import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/onboarding/p2p_onboarding_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/widgets/p2p_step_header.dart';

class CourierIdentityScreen extends StatelessWidget {
  const CourierIdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<P2pOnboardingBloc>(),
      child: const _IdentityView(),
    );
  }
}

class _IdentityView extends StatefulWidget {
  const _IdentityView();

  @override
  State<_IdentityView> createState() => _IdentityViewState();
}

class _IdentityViewState extends State<_IdentityView> {
  final _formKey = GlobalKey<FormBuilderState>();

  static const _idTypes = [
    'Passport',
    'National ID',
    'Driver\'s Licence',
    'Residence Permit',
  ];

  static const _nationalities = [
    'Afghan', 'Albanian', 'Algerian', 'American', 'Andorran', 'Angolan',
    'Argentine', 'Armenian', 'Australian', 'Austrian', 'Azerbaijani',
    'Bahamian', 'Bahraini', 'Bangladeshi', 'Barbadian', 'Belarusian',
    'Belgian', 'Belizean', 'Beninese', 'Bhutanese', 'Bolivian',
    'Bosnian', 'Botswanan', 'Brazilian', 'British', 'Bruneian',
    'Bulgarian', 'Burkinabé', 'Burundian', 'Cambodian', 'Cameroonian',
    'Canadian', 'Cape Verdean', 'Central African', 'Chadian', 'Chilean',
    'Chinese', 'Colombian', 'Comorian', 'Congolese', 'Costa Rican',
    'Croatian', 'Cuban', 'Cypriot', 'Czech', 'Danish', 'Djiboutian',
    'Dominican', 'Dutch', 'Ecuadorian', 'Egyptian', 'Emirati',
    'Equatorial Guinean', 'Eritrean', 'Estonian', 'Ethiopian',
    'Fijian', 'Finnish', 'French', 'Gabonese', 'Gambian', 'Georgian',
    'German', 'Ghanaian', 'Greek', 'Grenadian', 'Guatemalan', 'Guinean',
    'Guyanese', 'Haitian', 'Honduran', 'Hungarian', 'Icelandic',
    'Indian', 'Indonesian', 'Iranian', 'Iraqi', 'Irish', 'Israeli',
    'Italian', 'Ivorian', 'Jamaican', 'Japanese', 'Jordanian',
    'Kazakhstani', 'Kenyan', 'Korean', 'Kuwaiti', 'Kyrgyzstani',
    'Laotian', 'Latvian', 'Lebanese', 'Lesothoan', 'Liberian',
    'Libyan', 'Lithuanian', 'Luxembourgish', 'Macedonian', 'Malagasy',
    'Malawian', 'Malaysian', 'Maldivian', 'Malian', 'Maltese',
    'Mauritanian', 'Mauritian', 'Mexican', 'Moldovan', 'Mongolian',
    'Montenegrin', 'Moroccan', 'Mozambican', 'Namibian', 'Nepali',
    'New Zealander', 'Nicaraguan', 'Nigerian', 'Norwegian',
    'Omani', 'Pakistani', 'Panamanian', 'Paraguayan', 'Peruvian',
    'Philippine', 'Polish', 'Portuguese', 'Qatari', 'Romanian',
    'Russian', 'Rwandan', 'Saudi Arabian', 'Senegalese', 'Serbian',
    'Sierra Leonean', 'Singaporean', 'Slovak', 'Slovenian', 'Somali',
    'South African', 'South Sudanese', 'Spanish', 'Sri Lankan',
    'Sudanese', 'Surinamese', 'Swazi', 'Swedish', 'Swiss', 'Syrian',
    'Taiwanese', 'Tajikistani', 'Tanzanian', 'Thai', 'Togolese',
    'Trinidadian', 'Tunisian', 'Turkish', 'Turkmen', 'Ugandan',
    'Ukrainian', 'Uruguayan', 'Uzbekistani', 'Venezuelan', 'Vietnamese',
    'Yemeni', 'Zambian', 'Zimbabwean', 'Other',
  ];

  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Identity Verification'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          const P2pStepHeader(currentStep: 1, totalSteps: 5),
          Expanded(
            child: FormBuilder(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Legal Name'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'first_name',
                            decoration: const InputDecoration(
                              labelText: 'First name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: _required,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'last_name',
                            decoration: const InputDecoration(
                              labelText: 'Last name',
                            ),
                            validator: _required,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Date of Birth'),
                    const SizedBox(height: 8),
                    FormBuilderDateTimePicker(
                      name: 'dob',
                      inputType: InputType.date,
                      format: DateFormat('dd MMM yyyy'),
                      decoration: const InputDecoration(
                        labelText: 'Date of birth',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      firstDate: DateTime(1930),
                      lastDate: DateTime.now().subtract(
                          const Duration(days: 365 * 18)),
                      validator: (v) {
                        if (v == null) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Nationality'),
                    const SizedBox(height: 8),
                    FormBuilderDropdown<String>(
                      name: 'nationality',
                      decoration: const InputDecoration(
                        labelText: 'Nationality',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      validator: _required,
                      items: _nationalities
                          .map((n) => DropdownMenuItem(
                                value: n,
                                child: Text(n),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Residential Address'),
                    const SizedBox(height: 8),
                    GooglePlaceAutoCompleteTextField(
                      textEditingController: _addressController,
                      googleAPIKey: ApiConstants.googleMapApiKey,
                      inputDecoration: const InputDecoration(
                        labelText: 'Residential address',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      boxDecoration: const BoxDecoration(),
                      debounceTime: 400,
                      countries: const [],
                      isLatLngRequired: false,
                      getPlaceDetailWithLatLng: (_) {},
                      itemClick: (Prediction prediction) {
                        _addressController.text = prediction.description ?? '';
                        _addressController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _addressController.text.length));
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
                            prediction.structuredFormatting?.mainText ?? prediction.description ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            prediction.structuredFormatting?.secondaryText ?? '',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          dense: true,
                        );
                      },
                      isCrossBtnShown: false,
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('ID Type'),
                    const SizedBox(height: 8),
                    FormBuilderDropdown<String>(
                      name: 'id_type',
                      decoration: const InputDecoration(
                        labelText: 'Primary ID type',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: _required,
                      items: _idTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'id_number',
                      decoration: const InputDecoration(
                        labelText: 'ID number',
                        prefixIcon: Icon(Icons.numbers_outlined),
                      ),
                      validator: _required,
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
                          'Next: Travel Documents',
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
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your residential address')),
      );
      return;
    }
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    context.read<P2pOnboardingBloc>().add(
          P2pOnboardingIdentitySubmitted({
            'full_name':
                '${values['first_name']} ${values['last_name']}'.trim(),
            'first_name': values['first_name'],
            'last_name': values['last_name'],
            'dob': (values['dob'] as DateTime?)?.toIso8601String(),
            'nationality': values['nationality'],
            'address_line1': _addressController.text,
            'id_type': values['id_type'],
            'id_number': values['id_number'],
          }),
        );
    context.push('/p2p/courier/documents');
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
