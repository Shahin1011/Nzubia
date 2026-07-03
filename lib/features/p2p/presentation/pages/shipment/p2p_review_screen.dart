import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_review_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';

class P2pReviewScreen extends StatefulWidget {
  final String shipmentId;

  const P2pReviewScreen({super.key, required this.shipmentId});

  @override
  State<P2pReviewScreen> createState() => _P2pReviewScreenState();
}

class _P2pReviewScreenState extends State<P2pReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;
  String? _courierUserId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCourierUserId();
  }

  Future<void> _loadCourierUserId() async {
    try {
      final repo = GetIt.instance<P2pShipmentRepository>();
      final offers = await repo.listOffers(widget.shipmentId);
      final accepted = offers.firstWhere(
        (o) => o.status.name == 'accepted',
        orElse: () => offers.first,
      );
      _courierUserId = accepted.route?.courierProfile?.userId;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _courierUserId == null) return;
    setState(() => _submitting = true);

    try {
      await GetIt.instance<P2pReviewRepository>().createReview(
        reviewedUserId: _courierUserId!,
        shipmentRequestId: widget.shipmentId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _skip() => context.go('/dashboard');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Leave a Review'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Icon ──────────────────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: 44,
                      color: Colors.amber[600],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'How was your courier?',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your feedback helps the community find trustworthy couriers.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // ── Star rating ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starVal = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starVal),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            _rating >= starVal
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 44,
                            color: _rating >= starVal
                                ? Colors.amber[600]
                                : theme.colorScheme.outline
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_rating > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      _ratingLabel(_rating),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Comment ───────────────────────────────────────────────
                  TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText:
                          'Add a comment (optional) — e.g. package arrived on time and in great condition.',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Submit ────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          (_rating > 0 && !_submitting && _courierUserId != null)
                              ? _submit
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.primaryColor.withAlpha(60),
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
                              'Submit Review',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip for now',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      default:
        return 'Excellent!';
    }
  }
}
