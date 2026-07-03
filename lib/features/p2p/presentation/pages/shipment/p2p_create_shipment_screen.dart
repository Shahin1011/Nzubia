import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/shipment/p2p_shipment_bloc.dart';

class P2pCreateShipmentScreen extends StatelessWidget {
  const P2pCreateShipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<P2pShipmentBloc>(),
      child: const _CreateShipmentView(),
    );
  }
}

class _CreateShipmentView extends StatefulWidget {
  const _CreateShipmentView();

  @override
  State<_CreateShipmentView> createState() => _CreateShipmentViewState();
}

class _CreateShipmentViewState extends State<_CreateShipmentView> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _picker = ImagePicker();
  ItemCategory? _selectedCategory;
  final List<String> _photoPaths = [];

  // Restricted categories that trigger a warning (backend canonical set).
  static final _restrictedCategories = ItemCategory.restricted;

  late TextEditingController _pickupController;
  late TextEditingController _deliveryController;
  String _deliveryCity = '';
  String _deliveryCountry = '';
  double? _pickupLat;
  double? _pickupLng;

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController();
    _deliveryController = TextEditingController();
    _pickupController.addListener(() {
      if (_pickupLat != null || _pickupLng != null) {
        setState(() {
          _pickupLat = null;
          _pickupLng = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showWarning =
        _selectedCategory != null &&
        _restrictedCategories.contains(_selectedCategory);

    return BlocListener<P2pShipmentBloc, P2pShipmentState>(
      listener: (context, state) {
        if (state.status == P2pShipmentStatus.success &&
            state.selectedRequest != null) {
          final req = state.selectedRequest!;
          context.pushReplacement(
            '/p2p/shipment/${req.id}/offers',
            extra: {
              'destinationCity': req.destinationCity,
              'destinationCountry': req.destinationCountry,
            },
          );
        }
        if (state.status == P2pShipmentStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Submission failed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: const Text('Send a Package'),
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
                // ── Compliance warning ──────────────────────────────
                if (showWarning)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.amber[800],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Restricted Category',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.amber[900],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Items in this category may require special documentation '
                                'or may be refused by some couriers. '
                                'Please check compliance guidelines before proceeding.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => context.push('/p2p/compliance'),
                                child: Text(
                                  'View compliance guidelines →',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Package details ─────────────────────────────────
                _SectionLabel('Package Details'),
                const SizedBox(height: 8),
                FormBuilderTextField(
                  name: 'item_description',
                  decoration: const InputDecoration(
                    labelText: 'Item description',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Text(
                  'Category',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ItemCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return FilterChip(
                      label: Text(cat.label),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontSize: 13,
                      ),
                      checkmarkColor: Colors.white,
                      backgroundColor: theme.colorScheme.outline.withValues(
                        alpha: 0.12,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // ── Weight & dimensions ─────────────────────────────
                _SectionLabel('Weight & Dimensions'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'weight_kg',
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          suffixText: 'kg',
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'declared_value_usd',
                        decoration: const InputDecoration(
                          labelText: 'Declared value',
                          prefixText: '\$',
                          prefixIcon: Icon(Icons.attach_money_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'length_cm',
                        decoration: const InputDecoration(
                          labelText: 'L (cm)',
                          suffixText: 'cm',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'width_cm',
                        decoration: const InputDecoration(
                          labelText: 'W (cm)',
                          suffixText: 'cm',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'height_cm',
                        decoration: const InputDecoration(
                          labelText: 'H (cm)',
                          suffixText: 'cm',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Pickup / delivery ───────────────────────────────
                _SectionLabel('Pickup Location'),
                const SizedBox(height: 8),
                GooglePlaceAutoCompleteTextField(
                  textEditingController: _pickupController,
                  googleAPIKey: ApiConstants.googleMapApiKey,
                  inputDecoration: const InputDecoration(
                    labelText: 'Pickup address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  boxDecoration: const BoxDecoration(),
                  debounceTime: 400,
                  countries: const [],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    setState(() {
                      _pickupLat = double.tryParse(prediction.lat ?? '');
                      _pickupLng = double.tryParse(prediction.lng ?? '');
                    });
                  },
                  itemClick: (Prediction prediction) {
                    _pickupController.text = prediction.description ?? '';
                    _pickupController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _pickupController.text.length),
                    );
                    FocusScope.of(context).unfocus();
                  },
                  seperatedBuilder: const Divider(height: 1),
                  containerVerticalPadding: 0,
                  itemBuilder: (context, index, Prediction prediction) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        prediction.structuredFormatting?.mainText ??
                            prediction.description ??
                            '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        prediction.structuredFormatting?.secondaryText ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      dense: true,
                    );
                  },
                  isCrossBtnShown: false,
                ),

                const SizedBox(height: 16),
                _SectionLabel('Delivery Location'),
                const SizedBox(height: 8),
                GooglePlaceAutoCompleteTextField(
                  textEditingController: _deliveryController,
                  googleAPIKey: ApiConstants.googleMapApiKey,
                  inputDecoration: const InputDecoration(
                    labelText: 'Delivery address',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  boxDecoration: const BoxDecoration(),
                  debounceTime: 400,
                  countries: const [],
                  isLatLngRequired: false,
                  getPlaceDetailWithLatLng: (_) {},
                  itemClick: (Prediction prediction) {
                    _deliveryController.text = prediction.description ?? '';
                    _deliveryController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _deliveryController.text.length),
                    );
                    final terms = prediction.terms ?? [];
                    setState(() {
                      _deliveryCity = terms.isNotEmpty
                          ? (terms.first.value ?? '')
                          : '';
                      _deliveryCountry = terms.length > 1
                          ? (terms.last.value ?? '')
                          : '';
                    });
                    FocusScope.of(context).unfocus();
                  },
                  seperatedBuilder: const Divider(height: 1),
                  containerVerticalPadding: 0,
                  itemBuilder: (context, index, Prediction prediction) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        prediction.structuredFormatting?.mainText ??
                            prediction.description ??
                            '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        prediction.structuredFormatting?.secondaryText ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      dense: true,
                    );
                  },
                  isCrossBtnShown: false,
                ),

                const SizedBox(height: 16),
                FormBuilderDateTimePicker(
                  name: 'needed_by_date',
                  inputType: InputType.date,
                  format: DateFormat('dd MMM yyyy'),
                  decoration: const InputDecoration(
                    labelText: 'Needed by date',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  validator: (v) => v == null ? 'Required' : null,
                ),

                const SizedBox(height: 20),

                // ── Photos ──────────────────────────────────────────
                _SectionLabel('Photos (optional)'),
                const SizedBox(height: 8),
                _PhotoGrid(
                  paths: _photoPaths,
                  onAdd: _pickPhoto,
                  onRemove: (i) => setState(() => _photoPaths.removeAt(i)),
                ),

                const SizedBox(height: 32),
                BlocBuilder<P2pShipmentBloc, P2pShipmentState>(
                  builder: (context, state) {
                    final isLoading = state.status == P2pShipmentStatus.loading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return 'Required';
    return null;
  }

  String? _positiveNumber(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return 'Required';
    final n = double.tryParse(v.toString());
    if (n == null || n <= 0) return 'Enter a positive number';
    return null;
  }

  Future<void> _pickPhoto() async {
    if (_photoPaths.length >= 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 4 photos allowed')));
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked != null) {
      setState(() => _photoPaths.add(picked.path));
    }
  }

  void _onSubmit() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a pickup location')),
      );
      return;
    }
    if (_deliveryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery location')),
      );
      return;
    }
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final v = _formKey.currentState!.value;

    final length = double.tryParse(v['length_cm']?.toString() ?? '');
    final width = double.tryParse(v['width_cm']?.toString() ?? '');
    final height = double.tryParse(v['height_cm']?.toString() ?? '');
    final hasDims =
        length != null &&
        width != null &&
        height != null &&
        length > 0 &&
        width > 0 &&
        height > 0;

    final deliveryText = _deliveryController.text.trim();
    final deliveryCity = _deliveryCity.isNotEmpty
        ? _deliveryCity
        : (deliveryText.contains(',')
              ? deliveryText.split(',').first.trim()
              : deliveryText);
    final deliveryCountry = _deliveryCountry.isNotEmpty
        ? _deliveryCountry
        : (deliveryText.contains(',')
              ? deliveryText.split(',').last.trim()
              : '');

    context.read<P2pShipmentBloc>().add(
      P2pShipmentCreateRequested({
        'itemDescription': v['item_description'],
        'itemCategory': _selectedCategory!.toJson(),
        'weightKg': double.tryParse(v['weight_kg']?.toString() ?? '') ?? 0,
        'declaredValueUsd':
            double.tryParse(v['declared_value_usd']?.toString() ?? '') ?? 0,
        'originAddress': _pickupController.text,
        if (_pickupLat != null) 'originLatitude': _pickupLat,
        if (_pickupLng != null) 'originLongitude': _pickupLng,
        'destinationCountry': deliveryCountry,
        'destinationCity': deliveryCity,
        if (hasDims)
          'dimensionsCm': {'length': length, 'width': width, 'height': height},
        if (_photoPaths.isNotEmpty) 'photoUrls': _photoPaths,
      }),
    );
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

class _PhotoGrid extends StatelessWidget {
  final List<String> paths;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotoGrid({
    required this.paths,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...List.generate(
          paths.length,
          (i) => _PhotoTile(path: paths[i], onRemove: () => onRemove(i)),
        ),
        if (paths.length < 4)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 28,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _PhotoTile({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
