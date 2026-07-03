import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_route_repository.dart';

class PostRouteScreen extends StatefulWidget {
  const PostRouteScreen({super.key});

  @override
  State<PostRouteScreen> createState() => _PostRouteScreenState();
}

class _PostRouteScreenState extends State<PostRouteScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final List<ItemCategory> _selectedCategories = [];
  bool _submitting = false;

  static const _countries = [
    'Ghana', 'Nigeria', 'United Kingdom', 'United States', 'France',
    'Germany', 'Canada', 'Australia', 'Netherlands', 'UAE', 'Kenya',
    'South Africa', 'China', 'Japan', 'India', 'Brazil', 'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Post a Route'),
        leading: const BackButton(),
      ),
      body: FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Origin ───────────────────────────────────────────
              _SectionLabel('Origin'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'origin_city',
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: _required,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderDropdown<String>(
                    name: 'origin_country',
                    decoration: const InputDecoration(labelText: 'Country'),
                    validator: _required,
                    items: _countries
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Destination ──────────────────────────────────────
              _SectionLabel('Destination'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'destination_city',
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.flight_land_outlined),
                    ),
                    validator: _required,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderDropdown<String>(
                    name: 'destination_country',
                    decoration: const InputDecoration(labelText: 'Country'),
                    validator: _required,
                    items: _countries
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Travel dates ─────────────────────────────────────
              _SectionLabel('Travel Dates'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: 'departure_date',
                    inputType: InputType.date,
                    format: DateFormat('dd MMM yyyy'),
                    decoration: const InputDecoration(
                      labelText: 'Departure',
                      prefixIcon: Icon(Icons.flight_takeoff_outlined),
                    ),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: 'return_date',
                    inputType: InputType.date,
                    format: DateFormat('dd MMM yyyy'),
                    decoration: const InputDecoration(
                      labelText: 'Return (optional)',
                      prefixIcon: Icon(Icons.flight_land_outlined),
                    ),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Capacity ─────────────────────────────────────────
              _SectionLabel('Capacity'),
              const SizedBox(height: 8),
              FormBuilderTextField(
                name: 'capacity_kg',
                decoration: const InputDecoration(
                  labelText: 'Available weight',
                  prefixIcon: Icon(Icons.scale_outlined),
                  suffixText: 'kg',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0 || n > 50) {
                    return 'Enter a weight between 0.1 and 50 kg';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Accepted categories ──────────────────────────────
              _SectionLabel('Accepted Item Categories'),
              const SizedBox(height: 4),
              Text(
                'Select what you\'re willing to carry.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
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
                      color: selected ? Colors.white : theme.colorScheme.onSurface,
                      fontSize: 13,
                    ),
                    checkmarkColor: Colors.white,
                    backgroundColor:
                        theme.colorScheme.outline.withValues(alpha: 0.12),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Notes ────────────────────────────────────────────
              FormBuilderTextField(
                name: 'notes',
                decoration: const InputDecoration(
                  labelText: 'Additional notes (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // ── CTAs ─────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => _submit(publish: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Save as Draft',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : () => _submit(publish: true),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.rocket_launch_outlined, size: 18),
                    label: Text(
                      _submitting ? 'Posting...' : 'Publish Route',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _submit({required bool publish}) async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item category.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final values = _formKey.currentState!.value;

    String? toIsoDate(dynamic v) =>
        v is DateTime ? v.toIso8601String().split('T').first : null;

    final originCity = (values['origin_city'] as String?)?.trim() ?? '';
    final originCountry = (values['origin_country'] as String?)?.trim() ?? '';

    final routeData = <String, dynamic>{
      'destinationCity': values['destination_city'],
      'destinationCountry': values['destination_country'],
      'departureDate': toIsoDate(values['departure_date']),
      if (values['return_date'] != null)
        'returnDate': toIsoDate(values['return_date']),
      'pickupOrigin': [originCity, originCountry]
          .where((p) => p.isNotEmpty)
          .join(', '),
      'capacityKg': double.tryParse(
              values['capacity_kg']?.toString() ?? '') ??
          0,
      'acceptedItemCategories':
          _selectedCategories.map((c) => c.toJson()).toList(),
      if ((values['notes'] as String?)?.isNotEmpty == true)
        'routeNotes': values['notes'],
    };

    try {
      final repo = GetIt.instance<P2pRouteRepository>();
      var route = await repo.createRoute(routeData);

      if (publish) {
        route = await repo.updateRouteStatus(route.id, RouteStatus.published);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publish
              ? 'Route published — senders can now find you!'
              : 'Route saved as draft.'),
          backgroundColor: Colors.green[700],
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
