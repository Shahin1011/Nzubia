import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';

/// Single-screen courier profile creation.
///
/// On load it checks whether the user already has a profile. If so it
/// immediately replaces itself with the dashboard. Otherwise it presents the
/// lightweight registration form (service radius + accepted categories +
/// optional reputation bio), calls POST /p2p/couriers/me on submit, and then
/// navigates to the dashboard with a prompt to upload identity documents.
class CourierOnboardingScreen extends StatefulWidget {
  const CourierOnboardingScreen({super.key});

  @override
  State<CourierOnboardingScreen> createState() =>
      _CourierOnboardingScreenState();
}

class _CourierOnboardingScreenState extends State<CourierOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _radiusController = TextEditingController();
  final _bioController = TextEditingController();

  final List<ItemCategory> _selectedCategories = [];
  bool _checking = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  Future<void> _checkExistingProfile() async {
    try {
      final profile =
          await GetIt.instance<P2pCourierRepository>().getMyProfile();
      if (!mounted) return;
      if (profile != null) {
        context.pushReplacement('/p2p/courier/dashboard');
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _checking = false);
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select at least one item category you can carry.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final payload = <String, dynamic>{
      'acceptedCategories':
          _selectedCategories.map((c) => c.toJson()).toList(),
      if (_radiusController.text.trim().isNotEmpty)
        'serviceRadiusKm':
            double.tryParse(_radiusController.text.trim()) ?? 0.0,
      if (_bioController.text.trim().isNotEmpty)
        'reputationSummary': _bioController.text.trim(),
    };

    try {
      final repo = GetIt.instance<P2pCourierRepository>();
      await repo.applyAsCourier(payload);
      await repo.submitForReview();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Application submitted! Our team will review your profile shortly.',
          ),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.green,
        ),
      );

      context.pushReplacement('/p2p/courier/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_checking) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Create Courier Profile'),
        leading: const BackButton(),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero ──────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flight_takeoff_rounded,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Almost there',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Fill in a few details to activate your courier account. '
                            'You\'ll upload your ID/passport after.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor.withOpacity(0.75),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Home location ─────────────────────────────────────────────
              _SectionLabel(theme, 'Home Location (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'e.g. Accra, Ghana',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Used to suggest pickups near you.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 20),

              // ── Service radius ────────────────────────────────────────────
              _SectionLabel(theme, 'Service Radius (km)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _radiusController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                decoration: InputDecoration(
                  hintText: 'e.g. 25',
                  prefixIcon: const Icon(Icons.radar_outlined),
                  suffixText: 'km',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0 || n > 500) {
                    return 'Enter a radius between 1 and 500 km';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text(
                'How far from your home location can you collect packages?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 24),

              // ── Accepted categories ───────────────────────────────────────
              _SectionLabel(theme, 'What can you carry?'),
              const SizedBox(height: 4),
              Text(
                'Select all categories you\'re comfortable transporting.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ItemCategory.values.map((cat) {
                  final selected = _selectedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat.label),
                    selected: selected,
                    onSelected: (val) => setState(() {
                      if (val) {
                        _selectedCategories.add(cat);
                      } else {
                        _selectedCategories.remove(cat);
                      }
                    }),
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    checkmarkColor: Colors.white,
                    backgroundColor:
                        theme.colorScheme.outline.withOpacity(0.1),
                    side: BorderSide(
                      color: selected
                          ? Colors.transparent
                          : theme.colorScheme.outline.withOpacity(0.35),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Bio / reputation summary ──────────────────────────────────
              _SectionLabel(theme, 'About You (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 400,
                decoration: InputDecoration(
                  hintText:
                      'Tell senders about yourself — your typical routes, '
                      'experience carrying packages, languages spoken…',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── KYC note ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue[700], size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After creating your profile you\'ll be prompted to '
                        'upload a government-issued ID or passport. '
                        'You can also do this later from the Courier Dashboard '
                        'under Documents.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue[800],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primaryColor.withAlpha(60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Create Courier Profile',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => context.push('/p2p/courier/apply'),
                  child: const Text('Learn how courier earnings work'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final ThemeData theme;
  final String label;

  const _SectionLabel(this.theme, this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        letterSpacing: 0.3,
      ),
    );
  }
}
