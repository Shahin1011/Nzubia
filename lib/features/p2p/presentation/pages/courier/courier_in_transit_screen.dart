import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_review_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';

class CourierInTransitScreen extends StatefulWidget {
  final String shipmentId;

  const CourierInTransitScreen({super.key, required this.shipmentId});

  @override
  State<CourierInTransitScreen> createState() =>
      _CourierInTransitScreenState();
}

class _CourierInTransitScreenState extends State<CourierInTransitScreen> {
  P2pShipmentRequest? _shipment;
  bool _loading = true;
  String? _loadError;

  final List<XFile> _proofPhotos = [];
  bool _uploading = false;
  bool _submitting = false;
  String? _submitError;

  // Review state
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _reviewSubmitting = false;
  bool _reviewDone = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadShipment();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShipment() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final s = await GetIt.instance<P2pShipmentRepository>()
          .getRequest(widget.shipmentId);
      if (!mounted) return;
      setState(() {
        _shipment = s;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    if (_proofPhotos.length >= 3) return;
    final source = await _showSourceDialog();
    if (source == null) return;
    final file =
        await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() => _proofPhotos.add(file));
  }

  Future<ImageSource?> _showSourceDialog() {
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
    final resp = await GetIt.instance<DioClient>()
        .dio
        .post(ApiConstants.fileUpload, data: formData);
    return resp.data['url'] as String?;
  }

  Future<void> _markDelivered() async {
    if (_proofPhotos.length < 2) {
      setState(() => _submitError = 'Upload at least 2 delivery proof photos');
      return;
    }
    setState(() {
      _uploading = true;
      _submitError = null;
    });

    List<String> photoUrls;
    try {
      photoUrls = [];
      for (final f in _proofPhotos) {
        final url = await _uploadPhoto(f);
        if (url != null) photoUrls.add(url);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _submitError = 'Photo upload failed: $e';
      });
      return;
    }

    setState(() {
      _uploading = false;
      _submitting = true;
    });

    try {
      final updated = await GetIt.instance<P2pShipmentRepository>()
          .confirmDelivery(widget.shipmentId, proofPhotoUrls: photoUrls);
      if (!mounted) return;
      setState(() {
        _shipment = updated;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery confirmed!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.toString();
      });
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }
    final shipment = _shipment;
    if (shipment == null) return;

    setState(() => _reviewSubmitting = true);
    try {
      await GetIt.instance<P2pReviewRepository>().createReview(
        reviewedUserId: shipment.seekerUserId,
        shipmentRequestId: shipment.id,
        rating: _rating,
        comment: _commentCtrl.text.trim().isNotEmpty
            ? _commentCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      setState(() {
        _reviewDone = true;
        _reviewSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _reviewSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review failed: $e')),
      );
    }
  }

  bool get _isDelivered {
    final s = _shipment?.status.toJson();
    return s == 'DELIVERED' || s == 'COMPLETED';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('In Transit')),
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('In Transit')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadShipment, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final shipment = _shipment!;
    final seeker = shipment.seeker;
    final receiverName = seeker?.fullName ?? 'the recipient';
    final busy = _uploading || _submitting;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('In Transit'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Chat'),
            onPressed: () {
              final roomId =
                  shipment.chatThreadId ?? shipment.id;
              context.push('/chat/$roomId', extra: receiverName);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shipment summary
            _SummaryCard(shipment: shipment),
            const SizedBox(height: 24),

            if (!_isDelivered) ...[
              Text('Delivery proof', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Add 2–3 photos at the delivery point (min 2 required)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              _PhotoRow(
                photos: _proofPhotos,
                onAdd:
                    _proofPhotos.length < 3 && !busy ? _pickPhoto : null,
                onRemove: busy
                    ? null
                    : (i) => setState(() => _proofPhotos.removeAt(i)),
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _submitError!,
                  style: TextStyle(
                      color: theme.colorScheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
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
                  onPressed: busy ? null : _markDelivered,
                  child: busy
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(_uploading
                                ? 'Uploading photos…'
                                : 'Confirming delivery…'),
                          ],
                        )
                      : const Text('Mark as Delivered'),
                ),
              ),
            ] else ...[
              // Delivered — show status and review section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      'Delivery confirmed! Awaiting seeker receipt.',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!_reviewDone) ...[
                Text('Leave a review',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'How was your experience with $receiverName?',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _StarRating(
                  rating: _rating,
                  onChanged:
                      _reviewSubmitting ? null : (r) => setState(() => _rating = r),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !_reviewSubmitting,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reviewSubmitting
                            ? null
                            : () => context.go('/p2p/courier/dashboard'),
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _reviewSubmitting ? null : _submitReview,
                        child: _reviewSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Submit Review'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 40),
                      const SizedBox(height: 8),
                      Text('Review submitted!',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            context.go('/p2p/courier/dashboard'),
                        child: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final P2pShipmentRequest shipment;

  const _SummaryCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipment', style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          _Row(
            icon: Icons.inventory_2_outlined,
            text: shipment.itemCategory.label,
          ),
          const SizedBox(height: 4),
          _Row(
            icon: Icons.location_on_outlined,
            text:
                '${shipment.destinationCity}, ${shipment.destinationCountry}',
          ),
          if (shipment.seeker?.fullName != null) ...[
            const SizedBox(height: 4),
            _Row(
              icon: Icons.person_outline,
              text: 'Receiver: ${shipment.seeker!.fullName!}',
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Row({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _PhotoRow extends StatelessWidget {
  final List<XFile> photos;
  final VoidCallback? onAdd;
  final void Function(int)? onRemove;

  const _PhotoRow(
      {required this.photos, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...List.generate(photos.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
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
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
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
                      color: theme.colorScheme.outlineVariant, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: theme.colorScheme.outline),
                    const SizedBox(height: 4),
                    Text('Add',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  final void Function(int)? onChanged;

  const _StarRating({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating;
        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(i + 1) : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              filled ? Icons.star : Icons.star_border,
              color: filled ? Colors.amber : Colors.grey,
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}
