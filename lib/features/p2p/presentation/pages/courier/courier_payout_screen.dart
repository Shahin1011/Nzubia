import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';

class CourierPayoutScreen extends StatefulWidget {
  const CourierPayoutScreen({super.key});

  @override
  State<CourierPayoutScreen> createState() => _CourierPayoutScreenState();
}

class _CourierPayoutScreenState extends State<CourierPayoutScreen>
    with WidgetsBindingObserver {
  final _repo = GetIt.instance<P2pCourierRepository>();

  P2pStripeConnectStatus? _status;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check status when user returns from the Stripe browser tab.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _status?.connected == true) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    setState(() { _loading = true; _error = null; });
    try {
      final status = await _repo.getStripeConnectStatus();
      if (mounted) setState(() { _status = status; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _connect() async {
    setState(() { _actionLoading = true; _error = null; });
    try {
      final result = await _repo.initiateStripeConnect();
      final uri = Uri.parse(result.onboardingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // Status will refresh when app is foregrounded again (didChangeAppLifecycleState).
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _actionLoading = false; });
    }
  }

  Future<void> _openDashboard() async {
    setState(() { _actionLoading = true; _error = null; });
    try {
      final url = await _repo.getStripeDashboardLink();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _actionLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Settings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loading ? null : _loadStatus,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusCard(status: _status),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 32),
                  _buildInfoSection(theme),
                  const SizedBox(height: 32),
                  _buildActionButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How payouts work',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.lock_outline,
          text: 'Your payment is held in escrow while the shipment is in transit.',
        ),
        const SizedBox(height: 10),
        _InfoRow(
          icon: Icons.check_circle_outline,
          text: 'Funds are released automatically when the seeker confirms delivery.',
        ),
        const SizedBox(height: 10),
        _InfoRow(
          icon: Icons.account_balance_outlined,
          text: 'Stripe deposits to your linked bank account within 1–2 business days.',
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final isFullyActive = _status?.payoutReady == true;
    final isConnected = _status?.connected == true;
    final isPending = isConnected && !isFullyActive;

    if (isFullyActive) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Stripe Dashboard'),
              onPressed: _actionLoading ? null : _openDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'View your balance, payout schedule, and bank account details in your Stripe Express dashboard.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _actionLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(isPending ? Icons.edit_outlined : Icons.account_balance_wallet_outlined),
            label: Text(isPending ? 'Continue Stripe Setup' : 'Connect Bank Account'),
            onPressed: _actionLoading ? null : _connect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isPending
              ? 'Your Stripe account is created but needs more details before payouts can be sent.'
              : 'You\'ll be taken to Stripe\'s secure onboarding to link your bank account. This takes about 2 minutes.',
          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final P2pStripeConnectStatus? status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon, title, subtitle) = _resolveState();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String, String) _resolveState() {
    if (status == null) {
      return (Colors.grey, Icons.help_outline, 'Unknown', 'Could not load status.');
    }
    if (!status!.connected) {
      return (Colors.orange, Icons.warning_amber_outlined, 'Not Connected', 'Link your bank account to receive payouts.');
    }
    if (status!.payoutReady == true) {
      return (Colors.green, Icons.verified_outlined, 'Payout Ready', 'Your bank account is connected. Payouts are automatic.');
    }
    return (Colors.blue, Icons.hourglass_top_outlined, 'Setup Pending', 'Stripe is reviewing your information. This usually takes a few minutes.');
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13))),
        ],
      ),
    );
  }
}
