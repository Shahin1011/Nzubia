import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/cargo_item_entity.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_wizard/shipment_wizard_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_wizard/shipment_wizard_event.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_wizard/shipment_wizard_state.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/features/auth/domain/entities/user_entity.dart';
import 'package:customer_nzubia_global/core/widgets/user_avatar.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';

class ShipmentWizardScreen extends StatelessWidget {
  const ShipmentWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ShipmentWizardBloc(
        shipmentRepository: sl(),
        authRepository: sl(),
      ),
      child: const ShipmentWizardView(),
    );
  }
}

class ShipmentWizardView extends StatelessWidget {
  const ShipmentWizardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShipmentWizardBloc, ShipmentWizardState>(
      listener: (context, state) {
        if (state.status == ShipmentWizardStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.success)),
          );
          context.pop(true);
        }
        if (state.status == ShipmentWizardStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? AppLocalizations.of(context)!.errorCreatingShipment)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.newShipment),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopNavigation(context, state),
                  _buildStepIndicator(context, state),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildStepContent(state),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
      },
    );
  }

  Widget _buildStepIndicator(BuildContext context, ShipmentWizardState state) {
    return EasyStepper(
      activeStep: state.currentStep,
      lineStyle: const LineStyle(
        lineLength: 60,
        lineThickness: 3,
        lineSpace: 5,
        lineType: LineType.normal,
      ),
      activeStepTextColor: AppTheme.primaryColor,
      finishedStepTextColor: Colors.black87,
      internalPadding: 20,
      showLoadingAnimation: false,
      stepRadius: 18,
      showStepBorder: false,
      steps: [
        EasyStep(
          customStep: CircleAvatar(
            radius: 20,
            backgroundColor: state.currentStep >= 0 ? AppTheme.primaryColor : Colors.grey[300],
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
          title: AppLocalizations.of(context)!.location,
        ),
        EasyStep(
          customStep: CircleAvatar(
            radius: 20,
            backgroundColor: state.currentStep >= 1 ? AppTheme.primaryColor : Colors.grey[300],
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          title: AppLocalizations.of(context)!.recipient,
        ),
        EasyStep(
          customStep: CircleAvatar(
            radius: 20,
            backgroundColor: state.currentStep >= 2 ? AppTheme.primaryColor : Colors.grey[300],
            child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
          ),
          title: AppLocalizations.of(context)!.cargo,
        ),
        EasyStep(
          customStep: CircleAvatar(
            radius: 20,
            backgroundColor: state.currentStep >= 3 ? AppTheme.primaryColor : Colors.grey[300],
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
          ),
          title: AppLocalizations.of(context)!.service,
        ),
      ],
      onStepReached: (index) {
         // Optional: Allow tap to navigate
      },
    );
  }

  Widget _buildStepContent(ShipmentWizardState state) {
    switch (state.currentStep) {
      case 0:
        return const _LocationStep(key: ValueKey('location_step'));
      case 1:
        return const _RecipientStep(key: ValueKey('recipient_step'));
      case 2:
        return const _CargoStep(key: ValueKey('cargo_step'));
      case 3:
        return const _ServiceStep(key: ValueKey('service_step'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTopNavigation(BuildContext context, ShipmentWizardState state) {
    bool canGoNext = false;
    if (state.currentStep == 0) {
      canGoNext = state.origin.isNotEmpty && state.destination.isNotEmpty;
    } else if (state.currentStep == 1) {
       canGoNext = state.recipientName.isNotEmpty;
    } else if (state.currentStep == 2) {
      canGoNext = state.cargoItems.isNotEmpty;
    } else if (state.currentStep == 3) {
      canGoNext = state.legalGoodsTermsAccepted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: state.currentStep > 0
                  ? () => context.read<ShipmentWizardBloc>().add(ShipmentPreviousStep())
                  : () => context.pop(),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(state.currentStep > 0 ? AppLocalizations.of(context)!.back : 'Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: canGoNext
                  ? () {
                      if (state.currentStep == 3) {
                        context.read<ShipmentWizardBloc>().add(ShipmentSubmitted());
                      } else {
                        context.read<ShipmentWizardBloc>().add(ShipmentNextStep());
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: state.status == ShipmentWizardStatus.loading && state.currentStep == 3
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(state.currentStep == 3 ? AppLocalizations.of(context)!.submitRequest : AppLocalizations.of(context)!.next),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientStep extends StatefulWidget {
  const _RecipientStep({super.key});

  @override
  State<_RecipientStep> createState() => _RecipientStepState();
}

class _RecipientStepState extends State<_RecipientStep> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

  bool _initialized = false;
  String _currentPhone = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _initializeControllers(ShipmentWizardState state) {
    if (!_initialized) {
      _nameController.text = state.recipientName;
      _emailController.text = state.recipientEmail;
      _addressController.text = state.recipientAddress;
      _currentPhone = state.recipientPhone;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShipmentWizardBloc, ShipmentWizardState>(
      buildWhen: (p, c) => !_initialized,
      builder: (context, state) {
        final theme = Theme.of(context);
        _initializeControllers(state);
        return Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            key: const ValueKey(1),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.recipientDetails, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.whoIsReceivingShipment, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.recipientName,
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (val) => (val == null || val.length < 2) ? AppLocalizations.of(context)!.nameRequired : null,
                onChanged: (val) => context.read<ShipmentWizardBloc>().add(ShipmentRecipientInfoChanged(
                   name: val, email: _emailController.text, phone: _currentPhone, address: _addressController.text)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                 controller: _emailController,
                 focusNode: _emailFocus,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                    prefixIcon: const Icon(Icons.email),
                  ),
                 keyboardType: TextInputType.emailAddress,
                 validator: (val) {
                   if (val == null || val.isEmpty) return AppLocalizations.of(context)!.emailRequired;
                   if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return AppLocalizations.of(context)!.invalidEmail;
                   return null;
                 },
                 onChanged: (val) => context.read<ShipmentWizardBloc>().add(ShipmentRecipientInfoChanged(
                   name: _nameController.text, email: val, phone: _currentPhone, address: _addressController.text)),
              ),
              const SizedBox(height: 16),
              IntlPhoneField(
                 initialValue: _currentPhone,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.phoneNumber,
                  ),
                  initialCountryCode: 'US',
                 onChanged: (phone) {
                   _currentPhone = phone.completeNumber;
                   context.read<ShipmentWizardBloc>().add(ShipmentRecipientInfoChanged(
                     name: _nameController.text, email: _emailController.text, phone: phone.completeNumber, address: _addressController.text));
                 },
              ),
              const SizedBox(height: 16),
               TextFormField(
                 controller: _addressController,
                 focusNode: _addressFocus,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.detailedAddress,
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                 maxLines: 2,
                 validator: (val) => (val == null || val.length < 5) ? AppLocalizations.of(context)!.addressRequired : null,
                 onChanged: (val) => context.read<ShipmentWizardBloc>().add(ShipmentRecipientInfoChanged(
                   name: _nameController.text, email: _emailController.text, phone: _currentPhone, address: val)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationStep extends StatefulWidget {
  const _LocationStep({super.key});

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  late TextEditingController _originController;
  late TextEditingController _destController;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController();
    _destController = TextEditingController();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context, bool isPickup) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && context.mounted) {
        final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        context.read<ShipmentWizardBloc>().add(
          ShipmentDatesSelected(
            pickupDate: isPickup ? dateTime : context.read<ShipmentWizardBloc>().state.pickupDate,
            deliveryDate: !isPickup ? dateTime : context.read<ShipmentWizardBloc>().state.deliveryDate,
          )
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShipmentWizardBloc, ShipmentWizardState>(
      buildWhen: (p, c) =>
        (p.origin.isEmpty && c.origin.isNotEmpty && _originController.text.isEmpty) ||
        (p.destination.isEmpty && c.destination.isNotEmpty && _destController.text.isEmpty) ||
        p.pickupDate != c.pickupDate ||
        p.deliveryDate != c.deliveryDate,
      builder: (context, state) {
        // Initialize controllers only once
        if (state.origin.isNotEmpty && _originController.text.isEmpty) _originController.text = state.origin;
        if (state.destination.isNotEmpty && _destController.text.isEmpty) _destController.text = state.destination;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Origin Address
              GooglePlaceAutoCompleteTextField(
                textEditingController: _originController,
                googleAPIKey: ApiConstants.googleMapApiKey,
                inputDecoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.originAddress,
                  prefixIcon: const Icon(Icons.my_location),
                  suffixIcon: _originController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _originController.clear();
                            context.read<ShipmentWizardBloc>().add(const ShipmentOriginChanged(''));
                          },
                        )
                      : null,
                ),
                boxDecoration: const BoxDecoration(), // Disable package default border
                debounceTime: 400,
                countries: const [],
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  context.read<ShipmentWizardBloc>().add(ShipmentOriginChanged(prediction.description ?? ''));
                },
                itemClick: (Prediction prediction) {
                  _originController.text = prediction.description ?? '';
                  _originController.selection = TextSelection.fromPosition(TextPosition(offset: _originController.text.length));
                  context.read<ShipmentWizardBloc>().add(ShipmentOriginChanged(_originController.text));
                  FocusScope.of(context).unfocus();
                },
                seperatedBuilder: const Divider(height: 1),
                containerVerticalPadding: 0,
                itemBuilder: (context, index, Prediction prediction) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.location_on, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      prediction.structuredFormatting?.mainText ?? prediction.description ?? "",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      prediction.structuredFormatting?.secondaryText ?? "",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    dense: true,
                  );
                },
                isCrossBtnShown: false,
              ),
              const SizedBox(height: 16),
              // Destination Address
              GooglePlaceAutoCompleteTextField(
                textEditingController: _destController,
                googleAPIKey: ApiConstants.googleMapApiKey,
                inputDecoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.destinationAddress,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: _destController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _destController.clear();
                            context.read<ShipmentWizardBloc>().add(const ShipmentDestinationChanged(''));
                          },
                        )
                      : null,
                ),
                boxDecoration: const BoxDecoration(), // Disable package default border
                debounceTime: 400,
                countries: const [],
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  context.read<ShipmentWizardBloc>().add(ShipmentDestinationChanged(prediction.description ?? ''));
                },
                itemClick: (Prediction prediction) {
                   _destController.text = prediction.description ?? '';
                   _destController.selection = TextSelection.fromPosition(TextPosition(offset: _destController.text.length));
                   context.read<ShipmentWizardBloc>().add(ShipmentDestinationChanged(_destController.text));
                   FocusScope.of(context).unfocus();
                },
                seperatedBuilder: const Divider(height: 1),
                containerVerticalPadding: 0,
                itemBuilder: (context, index, Prediction prediction) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.location_on, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      prediction.structuredFormatting?.mainText ?? prediction.description ?? "",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      prediction.structuredFormatting?.secondaryText ?? "",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    dense: true,
                  );
                },
                isCrossBtnShown: false,
              ),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.scheduleOptional, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      context,
                      AppLocalizations.of(context)!.pickup,
                      state.pickupDate,
                      () => _pickDateTime(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePicker(
                      context,
                      AppLocalizations.of(context)!.delivery,
                      state.deliveryDate,
                      () => _pickDateTime(context, false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime? date, VoidCallback onTap) {
    final controller = TextEditingController(
      text: date != null ? DateFormat('MM/dd/yy HH:mm').format(date) : '',
    );
    
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: AppLocalizations.of(context)!.selectDate,
        prefixIcon: Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
      ),
    );
  }
}


class _CargoStep extends StatefulWidget {
  const _CargoStep({super.key});

  @override
  State<_CargoStep> createState() => _CargoStepState();
}

class _CargoStepState extends State<_CargoStep> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _qtyController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedCategory = 'GENERAL';
  bool _isFragile = false;
  bool _isPerishable = false;

  int? _editingIndex; // Track which item is being edited

  final List<String> _categories = ['GENERAL', 'ELECTRONICS', 'FURNITURE', 'CLOTHING', 'MACHINERY', 'PERISHABLE', 'OTHER'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _weightController.dispose();
    _qtyController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context)!.camera), // I should add camera/gallery to ARB
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)!.gallery),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || !context.mounted) return;

    try {
      List<XFile> pickedFiles = [];
      if (result == 'camera') {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80, // Optimize size immediately
        );
        if (photo != null) {
          pickedFiles = [photo];
        }
      } else if (result == 'gallery') {
        pickedFiles = await _picker.pickMultiImage(
           maxWidth: 1024,
           maxHeight: 1024,
           imageQuality: 80,
        );
      }

      if (pickedFiles.isNotEmpty && context.mounted) {
          // Validate image sizes (max 20MB per image)
          const int maxSizeInBytes = 20 * 1024 * 1024; // 20 MB
          final List<String> validPaths = [];
          final List<String> oversizedFiles = [];

          for (final file in pickedFiles) {
            try {
              final fileSize = await File(file.path).length();
              if (fileSize > maxSizeInBytes) {
                oversizedFiles.add(file.name);
              } else {
                validPaths.add(file.path);
              }
            } catch (e) {
              debugPrint('Error accessing file: $e');
            }
          }

          if (oversizedFiles.isNotEmpty && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${oversizedFiles.length} file(s) too large (max 20MB). Remaining ${validPaths.length} added.'),
                backgroundColor: Colors.orange,
              ),
            );
          }

         if (validPaths.isNotEmpty && context.mounted) {
           final currentPaths = context.read<ShipmentWizardBloc>().state.tempCargoImagePaths;
           context.read<ShipmentWizardBloc>().add(ShipmentCargoImageSelected([...currentPaths, ...validPaths]));
         }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorPickingImage}: $e')),
        );
      }
    }
  }

  void _onEditItem(int index, CargoItemEntity item) {
    setState(() {
      _editingIndex = index;
      _descriptionController.text = item.description;
      _weightController.text = item.weight.toString();
      _qtyController.text = item.quantity.toString();
      _lengthController.text = item.length > 0 ? item.length.toString() : '';
      _widthController.text = item.width > 0 ? item.width.toString() : '';
      _heightController.text = item.height > 0 ? item.height.toString() : '';
      _selectedCategory = item.category;
      _isFragile = item.isFragile;
      _isPerishable = item.isPerishable;
    });
    // Load images into temp state so they can be seen/edited
    context.read<ShipmentWizardBloc>().add(ShipmentCargoImageSelected(item.imageUrls));
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _resetForm();
    });
    context.read<ShipmentWizardBloc>().add(const ShipmentCargoImageSelected([]));
  }

  void _saveItem(BuildContext context, List<String> imagePaths) {
     if (!_formKey.currentState!.validate()) return;

     final item = CargoItemEntity(
       id: _editingIndex != null
          ? context.read<ShipmentWizardBloc>().state.cargoItems[_editingIndex!].id
          : DateTime.now().toString(),
       description: _descriptionController.text,
       weight: double.tryParse(_weightController.text) ?? 0.0,
       length: double.tryParse(_lengthController.text) ?? 0.0,
       width: double.tryParse(_widthController.text) ?? 0.0,
       height: double.tryParse(_heightController.text) ?? 0.0,
       quantity: int.tryParse(_qtyController.text) ?? 1,
       category: _selectedCategory,
       isFragile: _isFragile,
       isPerishable: _isPerishable,
       imageUrls: imagePaths,
     );

     if (_editingIndex != null) {
       context.read<ShipmentWizardBloc>().add(ShipmentCargoUpdated(_editingIndex!, item));
     } else {
       context.read<ShipmentWizardBloc>().add(ShipmentCargoAdded(item));
     }

     _cancelEdit(); // Resets form and editing index
  }

  void _resetForm() {
     _descriptionController.clear();
     _weightController.clear();
     _qtyController.clear();
     _lengthController.clear();
     _widthController.clear();
     _heightController.clear();
     _selectedCategory = 'GENERAL';
     _isFragile = false;
     _isPerishable = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShipmentWizardBloc, ShipmentWizardState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 // List of added items (Manifest)
                 if (state.cargoItems.isNotEmpty) ...[
                   Text(AppLocalizations.of(context)!.manifestWithCount(state.cargoItems.length), style: const TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   ListView.builder(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: state.cargoItems.length,
                     itemBuilder: (context, index) {
                       final item = state.cargoItems[index];
                       final isEditingThis = index == _editingIndex;
                       return Container(
                         color: isEditingThis ? Colors.blue.withValues(alpha: 0.1) : null,
                         child: ListTile(
                           leading: item.imageUrls.isNotEmpty
                              ? Image.file(File(item.imageUrls.first), width: 40, height: 40, fit: BoxFit.cover)
                              : const Icon(Icons.inventory_2),
                           title: Text(item.description),
                           subtitle: Text('${item.category} • ${item.weight.toStringAsFixed(2)} lbs / ${(item.weight * 0.453592).toStringAsFixed(1)} kg'),
                           trailing: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               IconButton(
                                 icon: const Icon(Icons.edit, color: Colors.blue),
                                 onPressed: () => _onEditItem(index, item),
                               ),
                               IconButton(
                                 icon: const Icon(Icons.delete, color: Colors.red),
                                 onPressed: () {
                                   if (_editingIndex == index) _cancelEdit();
                                   context.read<ShipmentWizardBloc>().add(ShipmentCargoRemoved(index));
                                 },
                               ),
                             ],
                           ),
                         ),
                       );
                     },
                   ),
                   const Divider(height: 32),
                 ],

                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Text(_editingIndex != null ? AppLocalizations.of(context)!.edit : AppLocalizations.of(context)!.addCargoItem,
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (_editingIndex != null)
                         TextButton(onPressed: _cancelEdit, child: Text(AppLocalizations.of(context)!.cancel)),
                   ],
                 ),
                 const SizedBox(height: 16),

                 // Category Dropdown
                 DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.category, border: const OutlineInputBorder()),
                   items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                   onChanged: (val) => setState(() => _selectedCategory = val!),
                 ),
                 const SizedBox(height: 12),

                 TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description, border: const OutlineInputBorder()),
                   validator: (value) {
                     if (value == null || value.trim().isEmpty) return 'Please enter a description';
                     return null;
                   },
                 ),
                 const SizedBox(height: 12),

                 // Weight & Qty
                 Row(
                   children: [
                     Expanded(
                       child: TextFormField(
                         controller: _weightController,
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.weightLbs, // Default to lbs as per request
                            helperText: '1 kg ≈ 2.2 lbs',
                            border: const OutlineInputBorder(),
                            hintText: AppLocalizations.of(context)!.optional,
                          ),
                         validator: (value) {
                            // Made optional
                            if (value == null || value.isEmpty) return null;
                            final v = double.tryParse(value);
                            if (v == null || v < 0) return 'Invalid';
                            return null;
                         },
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.quantity, border: const OutlineInputBorder()),
                         validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final v = int.tryParse(value);
                            if (v == null || v <= 0) return '> 0';
                            return null;
                         },
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),

                 // Dimensions (Optional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${AppLocalizations.of(context)!.dimensions} (${AppLocalizations.of(context)!.optional} - ${state.dimensionUnit})", style: const TextStyle(fontWeight: FontWeight.w500)),
                        ToggleButtons(
                       constraints: const BoxConstraints(minHeight: 32, minWidth: 48),
                       isSelected: [state.dimensionUnit == 'cm', state.dimensionUnit == 'inch'],
                       onPressed: (index) {
                         context.read<ShipmentWizardBloc>().add(ShipmentDimensionUnitChanged(index == 0 ? 'cm' : 'inch'));
                       },
                       borderRadius: BorderRadius.circular(8),
                       children: const [
                         Text('cm'),
                         Text('in'),
                       ],
                     ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Row(
                   children: [
                     Expanded(child: TextFormField(
                       controller: _lengthController,
                       keyboardType: TextInputType.number,
                       decoration: const InputDecoration(labelText: 'L', border: OutlineInputBorder(), hintText: 'Opt'),
                     )),
                     const SizedBox(width: 8),
                     Expanded(child: TextFormField(
                       controller: _widthController,
                       keyboardType: TextInputType.number,
                       decoration: const InputDecoration(labelText: 'W', border: OutlineInputBorder(), hintText: 'Opt'),
                     )),
                     const SizedBox(width: 8),
                     Expanded(child: TextFormField(
                       controller: _heightController,
                       keyboardType: TextInputType.number,
                       decoration: const InputDecoration(labelText: 'H', border: OutlineInputBorder(), hintText: 'Opt'),
                     )),
                   ],
                 ),
                 const SizedBox(height: 12),

                 // Attributes Switches
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.fragile),
                   value: _isFragile,
                   onChanged: (val) => setState(() => _isFragile = val),
                   contentPadding: EdgeInsets.zero,
                 ),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.perishable),
                   value: _isPerishable,
                   onChanged: (val) => setState(() => _isPerishable = val),
                   contentPadding: EdgeInsets.zero,
                 ),

                 const SizedBox(height: 12),

                  // Images Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          "${AppLocalizations.of(context)!.cargo} Photos (${AppLocalizations.of(context)!.optional})",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Max 20MB per image',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _pickImage(context),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: state.tempCargoImagePaths.isNotEmpty
                              ? ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.all(8),
                                  itemCount: state.tempCargoImagePaths.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == state.tempCargoImagePaths.length) {
                                      return Container(
                                        width: 80,
                                        color: Colors.grey[200],
                                        margin: const EdgeInsets.only(left: 8),
                                        child: const Icon(Icons.add_photo_alternate),
                                      );
                                    }
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              File(state.tempCargoImagePaths[index]), 
                                              width: 100, 
                                              height: 104,
                                              fit: BoxFit.cover
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                final updatedPaths = List<String>.from(state.tempCargoImagePaths);
                                                updatedPaths.removeAt(index);
                                                context.read<ShipmentWizardBloc>().add(
                                                  ShipmentCargoImageSelected(updatedPaths)
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(4),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                    Text(AppLocalizations.of(context)!.tapToAddPhotos),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                 const SizedBox(height: 16),

                 ElevatedButton.icon(
                    onPressed: () => _saveItem(context, state.tempCargoImagePaths),
                    icon: Icon(_editingIndex != null ? Icons.save : Icons.add),
                    label: Text(_editingIndex != null ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.add),
                    style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.secondaryColor,
                     foregroundColor: Colors.white,
                   ),
                 ),
               ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceStep extends StatefulWidget {
  const _ServiceStep({super.key});

  @override
  State<_ServiceStep> createState() => _ServiceStepState();
}

class _ServiceStepState extends State<_ServiceStep> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShipmentWizardBloc>().state;
    final selectedServices = state.selectedServices;

    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Air'),
          subtitle: const Text('Fastest delivery for urgent shipments.'),
          value: selectedServices.contains('AIR'),
          onChanged: (val) => context.read<ShipmentWizardBloc>().add(ShipmentServiceSelected('AIR')),
        ),
         CheckboxListTile(
          title: const Text('Sea'),
          subtitle: const Text('Best value for large cargo.'),
          value: selectedServices.contains('SEA'),
          onChanged: (val) => context.read<ShipmentWizardBloc>().add(ShipmentServiceSelected('SEA')),
        ),
        // Insurance Toggle
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.requestInsurance),
          subtitle: Text(AppLocalizations.of(context)!.insuranceSubtitle),
          value: state.isInsuranceRequested,
          onChanged: (val) {
             context.read<ShipmentWizardBloc>().add(ShipmentInsuranceRequestedChanged(val));
             if (!val) {
               context.read<ShipmentWizardBloc>().add(const ShipmentTotalItemValueChanged(0));
             }
          },
        ),
        if (state.isInsuranceRequested)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please enter the overall value of your items. You will pay an extra fee for insurance based on this value.',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              'You will receive the specific insurance cost at the quote section.',
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: state.totalItemValue > 0 ? state.totalItemValue.toString() : '',
                  decoration: const InputDecoration(
                    labelText: 'Overall Item Value (USD)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 500.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final value = double.tryParse(val) ?? 0;
                    context.read<ShipmentWizardBloc>().add(ShipmentTotalItemValueChanged(value));
                  },
                ),
              ],
            ),
          ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(AppLocalizations.of(context)!.estimatedPeriod, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        _buildServiceLevelOption(context, 'EXPRESS', 'Express', '1 - 4 weeks'),
        _buildServiceLevelOption(context, 'STANDARD', 'Standard', '4 - 8 weeks'),
        _buildServiceLevelOption(context, 'ECONOMY', 'Economy', '8 - 12 weeks'),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: state.legalGoodsTermsAccepted,
                onChanged: (val) {
                  context.read<ShipmentWizardBloc>().add(
                    ShipmentLegalGoodsConsentChanged(val ?? false),
                  );
                },
                activeColor: AppTheme.primaryColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    AppLocalizations.of(context)!.shipmentLegalConsent,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInsuranceValueModal(BuildContext context) {
    final bloc = context.read<ShipmentWizardBloc>();
    final controller = TextEditingController(
      text: bloc.state.totalItemValue > 0 ? bloc.state.totalItemValue.toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // Use root navigator to avoid being blocked
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield, color: Colors.blue),
                SizedBox(width: 8),
                Text('Insurance Verification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'To protect your items, please enter their total estimated value. You will be charged an additional fee for insurance based on this value.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The final insurance cost will be provided to you in the quotes you receive from agents.',
                      style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Overall Item Value (USD)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(controller.text) ?? 0;
                  if (val <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid item value')));
                    return;
                  }
                  bloc.add(const ShipmentInsuranceRequestedChanged(true));
                  bloc.add(ShipmentTotalItemValueChanged(val));
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirm & Request Insurance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  bloc.add(const ShipmentInsuranceRequestedChanged(false));
                  bloc.add(const ShipmentTotalItemValueChanged(0));
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel / Opt-Out', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceLevelOption(BuildContext context, String value, String title, String subtitle) {
    final currentLevel = context.watch<ShipmentWizardBloc>().state.serviceLevel;
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: currentLevel,
      onChanged: (val) {
        if (val != null) {
          context.read<ShipmentWizardBloc>().add(ShipmentServiceLevelSelected(val));
        }
      },
    );
  }
}

class _AgentStep extends StatelessWidget {
  const _AgentStep();

  void _showAgentDetails(BuildContext context, UserEntity agent) {
    final bloc = context.read<ShipmentWizardBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return BlocProvider.value(
          value: bloc,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header: Image & Basic Info
                    Row(
                      children: [
                        UserAvatar(
                          imageUrl: agent.profilePictureUrl,
                          name: "${agent.firstName ?? ''} ${agent.lastName ?? ''}".trim(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Row(
                                 children: [
                                   Flexible(
                                     child: Text(
                                       "${agent.firstName ?? ''} ${agent.lastName ?? ''}".trim(),
                                       style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                     ),
                                   ),
                                   if (agent.isVerified) ...[
                                     const SizedBox(width: 6),
                                     const Icon(Icons.verified, color: Colors.blue, size: 20),
                                   ]
                                 ],
                               ),
                               /*
                               if (agent.companyName != null)
                                 Text(agent.companyName!, style: TextStyle(color: Colors.grey[600])),
                               */
                               const SizedBox(height: 4),
                               Row(
                                 children: [
                                   const Icon(Icons.star, color: Colors.amber, size: 18),
                                   const SizedBox(width: 4),
                                   Text("${agent.rating?.toStringAsFixed(1) ?? 'N/A'} (${agent.reviewCount ?? 0} reviews)", style: const TextStyle(fontWeight: FontWeight.w600)),
                                 ],
                               ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Stats Grid
                    Row(
                      children: [
                        _buildStatCard("Orders", "${agent.ordersFulfilled ?? 0}", Icons.local_shipping),
                        const SizedBox(width: 12),
                        _buildStatCard("Since", "2023", Icons.calendar_today), // Keep year static or remove if dynamic needed
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Specializations
                    if (agent.specialization != null && agent.specialization!.isNotEmpty) ...[
                      const Text("Specializations", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: agent.specialization!.map((s) => Chip(
                          label: Text(s),
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          labelStyle: TextStyle(color: AppTheme.primaryColor),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // About (Mock) - Keeping static as 'About' field isn't in Entity yet, or we can make it conditional
                    const Text("About Agent", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      "Verified agent with a strong track record in global logistics. Specializes in handling fragile and high-value cargo with care. Committed to timely deliveries.",
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),

                     const SizedBox(height: 32),
                     SizedBox(
                       width: double.infinity,
                       child: ElevatedButton(
                         onPressed: () {
                           context.read<ShipmentWizardBloc>().add(ShipmentAgentSelected(agent.id));
                           context.pop(); // Close modal
                         },
                         child: const Text("Select Agent"),
                       ),
                     ),
                     const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShipmentWizardBloc>().state;

    if (state.isLoadingAgents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.availableAgents.isEmpty) {
      return const Center(child: Text("No agents found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.availableAgents.length,
      itemBuilder: (context, index) {
        final agent = state.availableAgents[index];
        final isSelected = state.selectedAgentId == agent.id;
        final displayName = agent.companyName ?? "${agent.firstName ?? ''} ${agent.lastName ?? ''}".trim();
        final nameToShow = displayName.isEmpty ? agent.email : displayName;

        return Card(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
          shape: isSelected ? RoundedRectangleBorder(side: BorderSide(color: AppTheme.primaryColor, width: 2), borderRadius: BorderRadius.circular(8)) : null,
          child: ListTile(
            leading: Stack(
              children: [
                  UserAvatar(
                    imageUrl: agent.profilePictureUrl,
                    name: displayName,
                    radius: 20,
                  ),
                if (agent.isVerified)
                  const Positioned(
                    right: 0, bottom: 0,
                    child: CircleAvatar(radius: 8, backgroundColor: Colors.white, child: Icon(Icons.verified, color: Colors.blue, size: 14)),
                  )
              ]
            ),
            title: Text(nameToShow, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text("${agent.rating ?? 'N/A'}"),
                const SizedBox(width: 8),
                Text("${agent.ordersFulfilled ?? 0} Orders", style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => _showAgentDetails(context, agent),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppTheme.primaryColor),
              ],
            ),
            onTap: () => context.read<ShipmentWizardBloc>().add(ShipmentAgentSelected(agent.id)),
          ),
        );
      },
    );
  }
}
