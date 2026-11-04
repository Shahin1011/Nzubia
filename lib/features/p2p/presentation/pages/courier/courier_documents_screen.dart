import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/onboarding/p2p_onboarding_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/widgets/p2p_step_header.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/selfie_capture_screen.dart';

class CourierDocumentsScreen extends StatelessWidget {
  const CourierDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<P2pOnboardingBloc>(),
      child: const _DocumentsView(),
    );
  }
}

class _DocumentsView extends StatefulWidget {
  const _DocumentsView();

  @override
  State<_DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<_DocumentsView> {
  final _picker = ImagePicker();

  String? _idDocumentPath;
  String? _selfiePath;
  String? _visaPath;

  @override
  void initState() {
    super.initState();
    final data = GetIt.instance<P2pOnboardingBloc>().state.collectedData;
    _idDocumentPath = data['id_document_path'] as String? ??
        data['passport_image_path'] as String?;
    _selfiePath = data['selfie_image_path'] as String?;
    _visaPath = data['visa_image_path'] as String?;
  }

  bool get _canContinue => _idDocumentPath != null && _selfiePath != null;

  String _getIdDocTitle(String idType) {
    switch (idType.toLowerCase()) {
      case 'passport':
        return 'Passport Photo';
      case 'national id':
        return 'National ID (NID)';
      case "driver's licence":
      case "driver's license":
        return "Driver's Licence";
      case 'residence permit':
        return 'Residence Permit';
      default:
        return idType.endsWith('ID') ||
                idType.endsWith('Permit') ||
                idType.endsWith('Licence')
            ? idType
            : '$idType Document';
    }
  }

  String _getIdDocSubtitle(String idType) {
    switch (idType.toLowerCase()) {
      case 'passport':
        return 'Photo page showing your full name, photo, and expiry date.';
      case 'national id':
        return 'Clear photo of your official National ID card.';
      case "driver's licence":
      case "driver's license":
        return 'Clear photo of your valid government driver\'s licence.';
      case 'residence permit':
        return 'Clear photo of your official residence permit card.';
      default:
        return 'Clear photo of your official $idType.';
    }
  }

  IconData _getIdDocIcon(String idType) {
    switch (idType.toLowerCase()) {
      case 'passport':
        return Icons.menu_book_outlined;
      case 'national id':
        return Icons.badge_outlined;
      case "driver's licence":
      case "driver's license":
        return Icons.directions_car_outlined;
      case 'residence permit':
        return Icons.home_work_outlined;
      default:
        return Icons.credit_card_outlined;
    }
  }

  String _getContinueButtonLabel(String idType) {
    if (_idDocumentPath == null && _selfiePath == null) {
      return 'Upload $idType & Selfie to continue';
    } else if (_idDocumentPath == null) {
      return 'Upload $idType to continue';
    } else if (_selfiePath == null) {
      return 'Take a Selfie to continue';
    }
    return 'Next: Insurance & Compliance';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onboardingState = context.watch<P2pOnboardingBloc>().state;
    final rawIdType =
        (onboardingState.collectedData['id_type'] as String?)?.trim();
    final effectiveIdType =
        (rawIdType != null && rawIdType.isNotEmpty) ? rawIdType : 'ID Document';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Identity & Documents'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          const P2pStepHeader(currentStep: 2, totalSteps: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload verification documents',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload your selected ID and a live selfie to verify your identity and complete background review.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(height: 24),

                  // 1. Dynamic Primary ID Document Card
                  _UploadCard(
                    title: _getIdDocTitle(effectiveIdType),
                    subtitle: _getIdDocSubtitle(effectiveIdType),
                    icon: _getIdDocIcon(effectiveIdType),
                    isRequired: true,
                    filePath: _idDocumentPath,
                    onTap: () => _pickImage('id_document'),
                    onClear: () => setState(() => _idDocumentPath = null),
                  ),
                  const SizedBox(height: 16),

                  // 2. Selfie Verification Card (Required for Authentication & Face Match)
                  _UploadCard(
                    title: 'Live Selfie',
                    subtitle:
                        'Take a clear selfie showing your face directly to match with your ID.',
                    icon: Icons.face_retouching_natural_outlined,
                    isRequired: true,
                    filePath: _selfiePath,
                    isSelfie: true,
                    onTap: () => _pickImage('selfie'),
                    onClear: () => setState(() => _selfiePath = null),
                  ),
                  const SizedBox(height: 16),

                  // 3. Visa / Entry Permit Card (Optional)
                  _UploadCard(
                    title: 'Visa / Entry Permit',
                    subtitle:
                        'Optional — Only needed if travelling to destinations requiring visa clearance.',
                    icon: Icons.document_scanner_outlined,
                    isRequired: false,
                    filePath: _visaPath,
                    onTap: () => _pickImage('visa'),
                    onClear: () => setState(() => _visaPath = null),
                  ),
                  const SizedBox(height: 16),

                  // Security callout box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outlined,
                            size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your documents and selfie are encrypted and stored securely. Used strictly for courier identity and background authentication.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canContinue ? _onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            theme.colorScheme.outline.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _getContinueButtonLabel(effectiveIdType),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(String field) async {
    if (field == 'selfie') {
      // Launch in-app front camera directly with oval KYC face guide
      final capturedPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const SelfieCaptureScreen(),
        ),
      );
      if (capturedPath != null && mounted) {
        setState(() => _selfiePath = capturedPath);
      }
      return;
    }

    final source = await _showSourceDialog();
    if (source == null) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (picked == null) return;
      setState(() {
        if (field == 'id_document') {
          _idDocumentPath = picked.path;
        } else if (field == 'visa') {
          _visaPath = picked.path;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to access camera/gallery: $e')),
        );
      }
    }
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upload Document',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onNext() {
    context.read<P2pOnboardingBloc>().add(
          P2pOnboardingDocumentsSubmitted({
            'id_document_path': _idDocumentPath,
            'passport_image_path': _idDocumentPath,
            'selfie_image_path': _selfiePath,
            if (_visaPath != null) 'visa_image_path': _visaPath,
          }),
        );
    context.push('/p2p/courier/compliance');
  }
}

// ─── Upload card ──────────────────────────────────────────────────────────────

class _UploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isRequired;
  final String? filePath;
  final bool isSelfie;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isRequired,
    required this.filePath,
    this.isSelfie = false,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = filePath != null;

    return GestureDetector(
      onTap: hasFile ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile
                ? AppTheme.primaryColor
                : theme.colorScheme.outline,
            width: hasFile ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: hasFile
            ? _FilePreview(
                filePath: filePath!,
                title: title,
                isSelfie: isSelfie,
                onClear: onClear,
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                          size: 19),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isRequired
                                      ? AppTheme.primaryColor.withAlpha(26)
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isRequired ? 'Required' : 'Optional',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isRequired
                                        ? AppTheme.primaryColor
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.65),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelfie
                          ? Icons.camera_front_outlined
                          : Icons.upload_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  final String filePath;
  final String title;
  final bool isSelfie;
  final VoidCallback onClear;

  const _FilePreview({
    required this.filePath,
    required this.title,
    this.isSelfie = false,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(isSelfie ? 28 : 8),
            child: Image.file(
              File(filePath),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.primaryColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      isSelfie ? 'Selfie Captured' : 'Document Attached',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
