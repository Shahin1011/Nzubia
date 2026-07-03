import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/onboarding/p2p_onboarding_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/widgets/p2p_step_header.dart';

class CourierRouteScreen extends StatelessWidget {
  const CourierRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<P2pOnboardingBloc>(),
      child: const _RouteView(),
    );
  }
}

class _RouteView extends StatefulWidget {
  const _RouteView();

  @override
  State<_RouteView> createState() => _RouteViewState();
}

class _RouteViewState extends State<_RouteView> {
  final _formKey = GlobalKey<FormBuilderState>();
  final List<ItemCategory> _selectedCategories = [];

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
        title: const Text('Declare Your Route'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          const P2pStepHeader(currentStep: 3, totalSteps: 5),
          Expanded(
            child: FormBuilder(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Origin ──────────────────────────────────────────
                    _SectionLabel('Origin'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'origin_city',
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon:
                                  Icon(Icons.location_city_outlined),
                            ),
                            validator: _required,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FormBuilderDropdown<String>(
                            name: 'origin_country',
                            decoration: const InputDecoration(
                                labelText: 'Country'),
                            validator: _required,
                            items: _countries
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Destination ─────────────────────────────────────
                    _SectionLabel('Destination'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'destination_city',
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon:
                                  Icon(Icons.flight_land_outlined),
                            ),
                            validator: _required,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FormBuilderDropdown<String>(
                            name: 'destination_country',
                            decoration: const InputDecoration(
                                labelText: 'Country'),
                            validator: _required,
                            items: _countries
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Travel dates ────────────────────────────────────
                    _SectionLabel('Travel Dates'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderDateTimePicker(
                            name: 'departure_date',
                            inputType: InputType.date,
                            format: DateFormat('dd MMM yyyy'),
                            decoration: const InputDecoration(
                              labelText: 'Departure',
                              prefixIcon:
                                  Icon(Icons.flight_takeoff_outlined),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                            validator: (v) {
                              if (v == null) return 'Required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FormBuilderDateTimePicker(
                            name: 'arrival_date',
                            inputType: InputType.date,
                            format: DateFormat('dd MMM yyyy'),
                            decoration: const InputDecoration(
                              labelText: 'Arrival',
                              prefixIcon:
                                  Icon(Icons.flight_land_outlined),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                            validator: (v) {
                              if (v == null) return 'Required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Capacity & pricing ──────────────────────────────
                    _SectionLabel('Capacity & Pricing'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'available_weight_kg',
                            decoration: const InputDecoration(
                              labelText: 'Available weight (kg)',
                              prefixIcon: Icon(Icons.scale_outlined),
                              suffixText: 'kg',
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = double.tryParse(v);
                              if (n == null || n <= 0) {
                                return 'Enter a valid weight';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'price_per_kg',
                            decoration: const InputDecoration(
                              labelText: 'Price per kg (USD)',
                              prefixIcon: Icon(Icons.attach_money_outlined),
                              prefixText: '\$',
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = double.tryParse(v);
                              if (n == null || n < 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Accepted categories ─────────────────────────────
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
                        final isSelected =
                            _selectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat.label),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: 13,
                          ),
                          checkmarkColor: Colors.white,
                          backgroundColor:
                              theme.colorScheme.outline.withValues(alpha: 0.12),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Notes ───────────────────────────────────────────
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
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Next: Insurance & Compliance',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return 'Required';
    return null;
  }

  void _onNext() {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one item category.')),
      );
      return;
    }
    final values = _formKey.currentState!.value;

    final originCity = (values['origin_city'] as String?)?.trim() ?? '';
    final originCountry = (values['origin_country'] as String?)?.trim() ?? '';
    final pickupOrigin = [originCity, originCountry]
        .where((p) => p.isNotEmpty)
        .join(', ');

    String? toIsoDate(dynamic v) =>
        v is DateTime ? v.toIso8601String().split('T').first : null;

    context.read<P2pOnboardingBloc>().add(
          P2pOnboardingRouteSubmitted({
            'destinationCity': values['destination_city'],
            'destinationCountry': values['destination_country'],
            'departureDate': toIsoDate(values['departure_date']),
            if (values['arrival_date'] != null)
              'returnDate': toIsoDate(values['arrival_date']),
            'pickupOrigin': pickupOrigin.isEmpty
                ? (values['origin_city'] ?? 'Unknown')
                : pickupOrigin,
            'capacityKg': double.tryParse(
                    values['available_weight_kg']?.toString() ?? '') ??
                0,
            if (_selectedCategories.isNotEmpty)
              'acceptedItemCategories':
                  _selectedCategories.map((c) => c.toJson()).toList(),
            if ((values['notes'] as String?)?.isNotEmpty == true)
              'routeNotes': values['notes'],
          }),
        );
    context.push('/p2p/courier/compliance');
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
