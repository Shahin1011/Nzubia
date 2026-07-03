import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_review.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_review_repository.dart';

/// Public courier profile fetched by ID from `/p2p/couriers/:id` together
/// with that courier's reputation aggregate and reviews.
class CourierProfileScreen extends StatefulWidget {
  final String courierId;

  const CourierProfileScreen({super.key, required this.courierId});

  @override
  State<CourierProfileScreen> createState() => _CourierProfileScreenState();
}

class _CourierProfileScreenState extends State<CourierProfileScreen> {
  late Future<_ProfileBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileBundle> _load() async {
    final courierRepo = GetIt.instance<P2pCourierRepository>();
    final reviewRepo = GetIt.instance<P2pReviewRepository>();

    final profile = await courierRepo.getPublicProfile(widget.courierId);
    final reputation = await courierRepo.getReputation(widget.courierId);
    List<P2pReview> reviews = const [];
    try {
      reviews = await reviewRepo.getCourierReviews(widget.courierId);
    } catch (_) {
      reviews = const [];
    }
    return _ProfileBundle(
      profile: profile,
      reputation: reputation,
      reviews: reviews,
    );
  }

  void _retry() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<_ProfileBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryColor),
            );
          }
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onRetry: _retry,
            );
          }
          final bundle = snap.data!;
          return _ProfileBody(bundle: bundle);
        },
      ),
    );
  }
}

class _ProfileBundle {
  final P2pCourierProfile profile;
  final P2pCourierReputation reputation;
  final List<P2pReview> reviews;

  const _ProfileBundle({
    required this.profile,
    required this.reputation,
    required this.reviews,
  });
}

class _ProfileBody extends StatelessWidget {
  final _ProfileBundle bundle;

  const _ProfileBody({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = bundle.profile;
    final reputation = bundle.reputation;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppTheme.primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF1A6570)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: const Alignment(0, 0.6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withAlpha(40),
                      child: Text(
                        profile.displayName.isNotEmpty
                            ? profile.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BadgesRow(profile: profile),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        value: reputation.reviewCount.toString(),
                        label: 'Reviews',
                        icon: Icons.reviews_outlined,
                        color: Colors.green[600]!,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        value: reputation.averageRating >= 0.1
                            ? reputation.averageRating.toStringAsFixed(1)
                            : '—',
                        label: 'Avg Rating',
                        icon: Icons.star_outline,
                        color: Colors.amber[700]!,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        value: profile.isActive ? 'Yes' : 'No',
                        label: 'Available',
                        icon: Icons.circle,
                        color: profile.isActive
                            ? Colors.green[600]!
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (profile.reputationSummary?.isNotEmpty == true) ...[
                  Text(
                    'About',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      profile.reputationSummary!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (profile.acceptedCategories.isNotEmpty) ...[
                  Text(
                    'Accepted Categories',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: profile.acceptedCategories
                        .map(
                          (cat) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  'Reviews',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (bundle.reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'No reviews yet.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                    ),
                  )
                else
                  ...bundle.reviews.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewCard(review: r),
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgesRow extends StatelessWidget {
  final P2pCourierProfile profile;

  const _BadgesRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isApproved = profile.verificationState.isApproved;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _Badge(
          icon: isApproved ? Icons.verified : Icons.pending_outlined,
          label: profile.verificationState.label,
          color: isApproved ? Colors.green[600]! : Colors.orange[600]!,
        ),
        if (profile.payoutReady)
          _Badge(
            icon: Icons.payments_outlined,
            label: 'Payout Ready',
            color: Colors.blue[600]!,
          ),
        if (profile.rating >= 4.5)
          _Badge(
            icon: Icons.workspace_premium_outlined,
            label: 'Top Courier',
            color: Colors.amber[700]!,
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 3),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final P2pReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber[600],
                    size: 14,
                  ),
                ),
              ),
              const Spacer(),
              if (review.createdAt != null)
                Text(
                  dateFmt.format(review.createdAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontSize: 11),
                ),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64,
                color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Could not load courier profile',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
