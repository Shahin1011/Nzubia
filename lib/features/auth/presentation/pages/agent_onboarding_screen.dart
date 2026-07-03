import 'dart:io';
import 'package:flutter/services.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer_nzubia_global/core/utils/media_helper.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/agent_onboarding/agent_onboarding_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/agent_onboarding/agent_onboarding_event.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/agent_onboarding/agent_onboarding_state.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class AgentOnboardingScreen extends StatelessWidget {
  const AgentOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider(
      create: (context) => AgentOnboardingBloc(authRepository: sl(), initialUser: user),
      child: const AgentOnboardingView(),
    );
  }
}

class AgentOnboardingView extends StatelessWidget {
  const AgentOnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.agentVerification)),
      body: BlocListener<AgentOnboardingBloc, AgentOnboardingState>(
        listener: (context, state) {
          if (state.status == AgentOnboardingStatus.success) {
            context.read<AuthBloc>().add(UserRefreshRequested());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification Submitted! Waiting for approval.')),
            );
            context.go('/agent-dashboard');
          } else if (state.status == AgentOnboardingStatus.failure) {
            final lowerCaseError = (state.errorMessage ?? '').toLowerCase();
            final rawError = state.errorMessage ?? 'Verification Failed';
            
            String cleanMessage = rawError;
            if (rawError.contains('DioException')) {
               final match = RegExp(r'DioException \[[^\]]+\]: (.*)').firstMatch(rawError);
               if (match != null) cleanMessage = match.group(1) ?? rawError;
            } else if (rawError.startsWith('Exception:')) {
               cleanMessage = rawError.replaceFirst('Exception:', '').trim();
            }

            final isNetworkError = lowerCaseError.contains('internet') || 
                                   lowerCaseError.contains('connection timeout') ||
                                   lowerCaseError.contains('connection error') ||
                                   lowerCaseError.contains('socket') ||
                                   lowerCaseError.contains('network') ||
                                   lowerCaseError.contains('failed host lookup');

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 4),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  content: Row(
                    children: [
                      Icon(isNetworkError ? Icons.signal_wifi_off : Icons.error_outline, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isNetworkError 
                            ? 'No Internet Connection. Please check your network and try again.'
                            : cleanMessage,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.verifyIdentity,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.verifyIdentitySubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
              ),
              const SizedBox(height: 24),

              // Admin Feedback Banner
              BlocBuilder<AgentOnboardingBloc, AgentOnboardingState>(
                buildWhen: (p, c) => p.status != c.status, // Re-check on init/status change
                builder: (context, state) {
                  final user = context.read<AuthBloc>().state.user;
                  if (user?.kycNotes != null && user!.kycNotes!.isNotEmpty) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.feedback_outlined, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Feedback from Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.kycNotes!,
                            style: TextStyle(
                              fontSize: 13, 
                              color: Colors.blue.shade900,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              /*
              _AgentTypeSelector(),
              const SizedBox(height: 24),
              */

              _CommonFields(),
              const SizedBox(height: 16),

              _DynamicFields(),
              const SizedBox(height: 24),

              _MultiSelectFields(),
              const SizedBox(height: 32),

              _SubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}

/*
class _AgentTypeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentOnboardingBloc, AgentOnboardingState>(
      buildWhen: (p, c) => p.agentType != c.agentType,
      builder: (context, state) {
        return SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'INDIVIDUAL', label: Text(AppLocalizations.of(context)!.individual), icon: const Icon(Icons.person)),
            ButtonSegment(value: 'BUSINESS', label: Text(AppLocalizations.of(context)!.business), icon: const Icon(Icons.business)),
          ],
          selected: {state.agentType},
          onSelectionChanged: (Set<String> newSelection) {
            context.read<AgentOnboardingBloc>().add(AgentTypeChanged(newSelection.first));
          },
        );
      },
    );
  }
}
*/

class _CommonFields extends StatefulWidget {
  @override
  State<_CommonFields> createState() => _CommonFieldsState();
}

class _CommonFieldsState extends State<_CommonFields> {
  late TextEditingController _addressController;
  late TextEditingController _yearsController;
  late TextEditingController _fleetController;
  late TextEditingController _radiusController;
  final FocusNode _yearsFocusNode = FocusNode();
  final FocusNode _fleetFocusNode = FocusNode();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _yearsController = TextEditingController();
    _fleetController = TextEditingController();
    _radiusController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _yearsController.dispose();
    _fleetController.dispose();
    _radiusController.dispose();
    _yearsFocusNode.dispose();
    _fleetFocusNode.dispose();
    super.dispose();
  }

  void _initializeControllers(AgentOnboardingState state) {
    if (!_initialized) {
      _addressController.text = state.address;
      _yearsController.text = state.yearsInBusiness > 0 ? state.yearsInBusiness.toString() : '';
      _fleetController.text = state.fleetSize > 0 ? state.fleetSize.toString() : '';
      _radiusController.text = state.serviceRadiusKm != null && state.serviceRadiusKm! > 0 ? state.serviceRadiusKm.toString() : '';
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentOnboardingBloc, AgentOnboardingState>(
      buildWhen: (p, c) => !_initialized,
      builder: (context, state) {
        _initializeControllers(state);
        return Column(
          children: [
            // Business Address with Google Places
            GooglePlaceAutoCompleteTextField(
              textEditingController: _addressController,
              googleAPIKey: ApiConstants.googleMapApiKey,
              inputDecoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.businessAddressBaseLocation,
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _addressController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _addressController.clear();
                          context.read<AgentOnboardingBloc>().add(const OnboardingFieldChanged('address', ''));
                        },
                      )
                    : null,
              ),
              boxDecoration: const BoxDecoration(), // Disable package default border
              debounceTime: 400,
              countries: const [],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) {
                final address = prediction.description ?? '';
                final bloc = context.read<AgentOnboardingBloc>();
                bloc.add(OnboardingFieldChanged('address', address));
                // Capture lat/lng as base location
                if (prediction.lat != null) {
                  bloc.add(OnboardingFieldChanged('baseLat', prediction.lat));
                }
                if (prediction.lng != null) {
                  bloc.add(OnboardingFieldChanged('baseLng', prediction.lng));
                }
              },
              itemClick: (Prediction prediction) {
                final address = prediction.description ?? '';
                _addressController.text = address;
                _addressController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _addressController.text.length),
                );
                final bloc = context.read<AgentOnboardingBloc>();
                bloc.add(OnboardingFieldChanged('address', address));
                // Capture lat/lng as base location
                if (prediction.lat != null) {
                  bloc.add(OnboardingFieldChanged('baseLat', prediction.lat));
                }
                if (prediction.lng != null) {
                  bloc.add(OnboardingFieldChanged('baseLng', prediction.lng));
                }
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
            /*
            const SizedBox(height: 16),
            Row(
              children: [
                // Years in Business
                Expanded(
                  child: TextField(
                    controller: _yearsController,
                    focusNode: _yearsFocusNode,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.yearsInBusinessLabel,
                      prefixIcon: const Icon(Icons.history),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      context.read<AgentOnboardingBloc>().add(OnboardingFieldChanged('yearsInBusiness', val));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Fleet Size
                Expanded(
                  child: TextField(
                    controller: _fleetController,
                    focusNode: _fleetFocusNode,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fleetSizeLabel,
                      prefixIcon: const Icon(Icons.local_shipping),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      context.read<AgentOnboardingBloc>().add(OnboardingFieldChanged('fleetSize', val));
                    },
                  ),
                ),
              ],
            ),
            */
            const SizedBox(height: 16),
            // Fleet Size
            TextField(
              controller: _fleetController,
              focusNode: _fleetFocusNode,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.fleetSizeLabel,
                prefixIcon: const Icon(Icons.local_shipping),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                context.read<AgentOnboardingBloc>().add(OnboardingFieldChanged('fleetSize', val));
              },
            ),
            const SizedBox(height: 16),
            // Service Radius
            TextField(
              controller: _radiusController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.serviceRadiusKm,
                prefixIcon: const Icon(Icons.radar),
                helperText: AppLocalizations.of(context)!.serviceRadiusHelper,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                context.read<AgentOnboardingBloc>().add(OnboardingFieldChanged('serviceRadiusKm', val));
              },
            ),
          ],
        );
      },
    );
  }
}

class _DynamicFields extends StatefulWidget {
  @override
  State<_DynamicFields> createState() => _DynamicFieldsState();
}

class _DynamicFieldsState extends State<_DynamicFields> {
  // Business fields controllers
  late TextEditingController _companyNameController;
  late TextEditingController _businessRegController;
  late TextEditingController _taxIdController;
  late TextEditingController _licenseNumberController;

  // Individual fields controllers
  late TextEditingController _idNumberController;

  // Focus nodes
  final FocusNode _companyNameFocus = FocusNode();
  final FocusNode _businessRegFocus = FocusNode();
  final FocusNode _taxIdFocus = FocusNode();
  final FocusNode _licenseNumberFocus = FocusNode();
  final FocusNode _idNumberFocus = FocusNode();

  bool _businessInitialized = false;
  bool _individualInitialized = false;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _businessRegController = TextEditingController();
    _taxIdController = TextEditingController();
    _licenseNumberController = TextEditingController();
    _idNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _businessRegController.dispose();
    _taxIdController.dispose();
    _licenseNumberController.dispose();
    _idNumberController.dispose();
    _companyNameFocus.dispose();
    _businessRegFocus.dispose();
    _taxIdFocus.dispose();
    _licenseNumberFocus.dispose();
    _idNumberFocus.dispose();
    super.dispose();
  }

  void _initBusinessControllers(AgentOnboardingState state) {
    if (!_businessInitialized) {
      _companyNameController.text = state.companyName;
      _businessRegController.text = state.businessRegNumber;
      _taxIdController.text = state.taxId;
      _licenseNumberController.text = state.licenseNumber;
      _businessInitialized = true;
    }
  }

  void _initIndividualControllers(AgentOnboardingState state) {
    if (!_individualInitialized) {
      _idNumberController.text = state.idNumber;
      _individualInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentOnboardingBloc, AgentOnboardingState>(
      buildWhen: (previous, current) =>
         previous.agentType != current.agentType ||
         previous.idType != current.idType ||
         previous.idDocumentPath != current.idDocumentPath ||
         previous.selfiePath != current.selfiePath,
      builder: (context, state) {
        // Force Individual fields only to comply with Apple's request to remove business registration features
        _initIndividualControllers(state);
        return Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: state.idType,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.idType, prefixIcon: const Icon(Icons.badge)),
              items: [
                DropdownMenuItem(value: 'NATIONAL_ID', child: Text(AppLocalizations.of(context)!.nationalId)),
                DropdownMenuItem(value: 'PASSPORT', child: Text(AppLocalizations.of(context)!.passport)),
                DropdownMenuItem(value: 'DRIVERS_LICENSE', child: Text(AppLocalizations.of(context)!.driversLicense)),
              ],
              onChanged: (val) => context.read<AgentOnboardingBloc>().add(OnboardingFieldChanged('idType', val!)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idNumberController,
              focusNode: _idNumberFocus,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.idNumber,
                prefixIcon: const Icon(Icons.numbers),
              ),
              onChanged: (val) => context.read<AgentOnboardingBloc>().add(OnboardingFieldChanged('idNumber', val)),
            ),
            const SizedBox(height: 24),
            _FileUploadButton(
              label: AppLocalizations.of(context)!.uploadIdDocument,
              field: 'id_document',
              currentPath: state.idDocumentPath
            ),
            const SizedBox(height: 16),
            _FileUploadButton(
              label: AppLocalizations.of(context)!.uploadSelfie,
              field: 'selfie',
              currentPath: state.selfiePath
            ),
          ],
        );
      },
    );
  }
}

class _FileUploadButton extends StatelessWidget {
  final String label;
  final String field;
  final String currentPath;

  const _FileUploadButton({required this.label, required this.field, required this.currentPath});

  Future<void> _pickFile(BuildContext context) async {
    // Show dialog to choose between Camera, Gallery, or Document
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context)!.camera),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)!.gallery),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(AppLocalizations.of(context)!.documentPdfDoc),
                onTap: () => Navigator.pop(context, 'document'),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    File? file;
    if (source == 'camera') {
      file = await MediaPickerHelper.pickImage(source: ImageSource.camera);
    } else if (source == 'gallery') {
      file = await MediaPickerHelper.pickImage(source: ImageSource.gallery);
    } else if (source == 'document') {
      file = await MediaPickerHelper.pickDocument();
    }

    if (file != null) {
      context.read<AgentOnboardingBloc>().add(OnboardingFilePicked(field, file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPath.isNotEmpty;
    // Simple check if it's an image extension
    final isImage = isSelected && (currentPath.toLowerCase().endsWith('.jpg') ||
                                   currentPath.toLowerCase().endsWith('.jpeg') ||
                                   currentPath.toLowerCase().endsWith('.png'));

    return InkWell(
      onTap: () => _pickFile(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppTheme.primaryColor : const Color(0xFFCCCCCC)), // Sync with brandLightGray
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.cloud_upload,
                 color: isSelected ? AppTheme.primaryColor : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                isSelected ? AppLocalizations.of(context)!.fileSelected(currentPath.split('/').last) : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                ),
              ),
            ),
            if (isImage)
              SizedBox(
                width: 40, height: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(currentPath), fit: BoxFit.cover),
                ),
              )
            else if (isSelected)
               const Icon(Icons.description, size: 40, color: Colors.blueGrey)
          ],
        ),
      ),
    );
  }
}

class _MultiSelectFields extends StatefulWidget {
  @override
  State<_MultiSelectFields> createState() => _MultiSelectFieldsState();
}

class _MultiSelectFieldsState extends State<_MultiSelectFields> {
  final List<String> _cargos = ['General Cargo', 'Perishables', 'Hazardous', 'Vehicles', 'Electronics', 'Textiles'];
  late TextEditingController _regionController;

  @override
  void initState() {
    super.initState();
    _regionController = TextEditingController();
  }

  @override
  void dispose() {
    _regionController.dispose();
    super.dispose();
  }

  void _showMultiSelect(BuildContext context, String title, List<String> options, List<String> current, String field) {
    final bloc = context.read<AgentOnboardingBloc>();
    showDialog(
      context: context,
      builder: (ctx) {
        final selected = List<String>.from(current);
        return BlocProvider.value(
          value: bloc,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('${AppLocalizations.of(context)!.select} $title'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: options.map((opt) {
                       return CheckboxListTile(
                         title: Text(opt),
                         value: selected.contains(opt),
                         onChanged: (val) {
                           setState(() {
                             if (val == true) {
                               selected.add(opt);
                             } else {
                               selected.remove(opt);
                             }
                           });
                         },
                       );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      bloc.add(OnboardingFieldChanged(field, selected));
                      Navigator.pop(ctx);
                    },
                    child: Text(AppLocalizations.of(context)!.saveButton)
                  )
                ],
              );
            }
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.serviceRegionsAddLocations, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Service Region with Google Places
        GooglePlaceAutoCompleteTextField(
          textEditingController: _regionController,
          googleAPIKey: ApiConstants.googleMapApiKey,
          inputDecoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.searchStatesRegionsCities,
            prefixIcon: const Icon(Icons.map),
            suffixIcon: _regionController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _regionController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          boxDecoration: const BoxDecoration(), // Disable package default border
          debounceTime: 400,
          countries: const [],
          isLatLngRequired: false,
          getPlaceDetailWithLatLng: (Prediction prediction) {},
          itemClick: (Prediction prediction) {
            final newRegion = prediction.description ?? '';
            final currentState = context.read<AgentOnboardingBloc>().state;
            if (newRegion.isNotEmpty && !currentState.serviceRegions.contains(newRegion)) {
              final updatedList = List<String>.from(currentState.serviceRegions)..add(newRegion);
              context.read<AgentOnboardingBloc>().add(OnboardingFieldChanged('serviceRegions', updatedList));
            }
            _regionController.clear();
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
        const SizedBox(height: 8),
        // Only this part needs to rebuild when regions change
        BlocBuilder<AgentOnboardingBloc, AgentOnboardingState>(
          buildWhen: (previous, current) => previous.serviceRegions != current.serviceRegions,
          builder: (context, state) {
            return Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: state.serviceRegions.map((region) {
                return Chip(
                  label: Text(region, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    final updatedList = List<String>.from(state.serviceRegions)..remove(region);
                    context.read<AgentOnboardingBloc>().add(OnboardingFieldChanged('serviceRegions', updatedList));
                  },
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),

        BlocBuilder<AgentOnboardingBloc, AgentOnboardingState>(
          buildWhen: (p, c) => p.cargoSpecializations != c.cargoSpecializations,
          builder: (context, state) {
        return InkWell(
          onTap: () => _showMultiSelect(context, AppLocalizations.of(context)!.cargos, _cargos, state.cargoSpecializations, 'cargoSpecializations'),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.cargoSpecializations,
              prefixIcon: const Icon(Icons.inventory_2),
              suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            child: Text(
              state.cargoSpecializations.isEmpty ? AppLocalizations.of(context)!.selectCargos : state.cargoSpecializations.join(', '),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
          }
        ),
        const SizedBox(height: 16),

        BlocBuilder<AgentOnboardingBloc, AgentOnboardingState>(
          buildWhen: (p, c) => p.insuranceCertificateUrl != c.insuranceCertificateUrl,
          builder: (context, state) {
             return _FileUploadButton(
                  label: AppLocalizations.of(context)!.uploadInsuranceCertificate,
                  field: 'insurance',
                  currentPath: state.insuranceCertificateUrl
             );
          }
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentOnboardingBloc, AgentOnboardingState>(
        builder: (context, state) {
          return state.status == AgentOnboardingStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: () => context.read<AgentOnboardingBloc>().add(const OnboardingSubmitted()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: Text(AppLocalizations.of(context)!.submitVerification, style: const TextStyle(color: Colors.white, fontSize: 16)),
                );
        }
    );
  }
}
