import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';

class CourierPickupScreen extends StatefulWidget {
  final String shipmentId;

  const CourierPickupScreen({super.key, required this.shipmentId});

  @override
  State<CourierPickupScreen> createState() => _CourierPickupScreenState();
}

class _CourierPickupScreenState extends State<CourierPickupScreen> {
  static const int _codeLength = 6;

  final List<TextEditingController> _digitCtrls = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );

  final List<XFile> _photos = [];
  bool _uploading = false;
  bool _submitting = false;
  String? _error;

  P2pShipmentRequest? _shipment;
  bool _loadingShipment = true;
  String? _seekerPhone;
  String? _seekerName;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadShipment();
  }

  Future<void> _loadShipment() async {
    try {
      final repo = GetIt.instance<P2pShipmentRepository>();
      final s = await repo.getRequest(widget.shipmentId);
      if (mounted) {
        final currentUser = GetIt.instance<AuthRepository>().currentUser;
        final shipperPhone = s.seeker?.phone?.isNotEmpty == true
            ? s.seeker!.phone
            : currentUser?.phone;
        final shipperName = (s.seeker?.fullName?.isNotEmpty == true)
            ? s.seeker!.fullName
            : currentUser?.fullName;
        setState(() {
          _shipment = s;
          _seekerPhone = shipperPhone;
          _seekerName = shipperName?.isNotEmpty == true ? shipperName : null;
          _loadingShipment = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingShipment = false);
    }
  }

  @override
  void dispose() {
    for (final c in _digitCtrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _digitCtrls.map((c) => c.text).join();

  bool get _codeComplete => _code.length == _codeLength;

  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) return;
    final source = await _showSourceDialog();
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() => _photos.add(file));
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadPhoto(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    final response = await GetIt.instance<DioClient>().dio.post(
      ApiConstants.fileUpload,
      data: formData,
    );
    return response.data['url'] as String?;
  }

  Future<void> _submit() async {
    if (!_codeComplete) {
      setState(() => _error = 'Enter the full 6-digit code');
      return;
    }
    if (_photos.length < 2) {
      setState(() => _error = 'Upload at least 2 proof photos');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });

    List<String> photoUrls;
    try {
      photoUrls = [];
      for (final f in _photos) {
        final url = await _uploadPhoto(f);
        if (url != null) photoUrls.add(url);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = 'Photo upload failed: $e';
      });
      return;
    }

    setState(() {
      _uploading = false;
      _submitting = true;
    });

    try {
      await GetIt.instance<P2pShipmentRepository>().recordPickup(
        widget.shipmentId,
        pickupConfirmationCode: _code,
        proofPhotoUrls: photoUrls,
      );
      if (!mounted) return;
      context.pushReplacement(
        '/p2p/courier/shipment/${widget.shipmentId}/in-transit',
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final isWrongCode =
          msg.contains('401') || msg.contains('403') || msg.contains('code');
      setState(() {
        _submitting = false;
        _error = isWrongCode
            ? 'Incorrect code. Ask the seeker for the correct 6-digit code.'
            : msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _uploading || _submitting;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Confirm Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Pickup address ────────────────────────────────────────────
            if (_loadingShipment)
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            else if (_shipment != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(50),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup address',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _shipment!.originAddress,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _seekerPhone != null
                                ? () => launchUrl(
                                      Uri(scheme: 'tel', path: _seekerPhone),
                                    )
                                : null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: _seekerPhone != null
                                      ? AppTheme.primaryColor
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    _seekerPhone != null
                                        ? [
                                            if (_seekerName != null)
                                              _seekerName!,
                                            _seekerPhone!,
                                          ].join(' · ')
                                        : 'Contact phone: Unavailable',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _seekerPhone != null
                                          ? AppTheme.primaryColor
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w600,
                                      decoration: _seekerPhone != null
                                          ? TextDecoration.underline
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Meet the seeker here to collect the package.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            Text(
              'Enter the 6-digit code shown on the seeker\'s app',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            _OtpRow(
              controllers: _digitCtrls,
              focusNodes: _focusNodes,
              enabled: !busy,
            ),
            const SizedBox(height: 28),
            Text('Proof photos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Add 2–3 photos showing the item at pickup (min 2 required)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            _PhotoGrid(
              photos: _photos,
              onAdd: _photos.length < 3 && !busy ? _pickPhoto : null,
              onRemove: busy
                  ? null
                  : (i) => setState(() => _photos.removeAt(i)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: busy ? null : _submit,
                child: busy
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _uploading
                                ? 'Uploading photos…'
                                : 'Confirming pickup…',
                          ),
                        ],
                      )
                    : const Text('Confirm Pickup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool enabled;

  const _OtpRow({
    required this.controllers,
    required this.focusNodes,
    required this.enabled,
  });

  void _onChanged(String value, int index) {
    if (value.isEmpty) {
      if (index > 0) focusNodes[index - 1].requestFocus();
    } else {
      if (index < controllers.length - 1) {
        focusNodes[index + 1].requestFocus();
      } else {
        focusNodes[index].unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (i) {
        return SizedBox(
          width: 46,
          child: TextField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (v) => _onChanged(v, i),
          ),
        );
      }),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<XFile> photos;
  final VoidCallback? onAdd;
  final void Function(int)? onRemove;

  const _PhotoGrid({
    required this.photos,
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
        ...List.generate(photos.length, (i) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(photos[i].path),
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image_outlined),
                  ),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => onRemove!(i),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add photo',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
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
