import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/network/socket_client.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/shipment/p2p_shipment_bloc.dart';

class P2pHandoffScreen extends StatefulWidget {
  final String shipmentId;

  const P2pHandoffScreen({super.key, required this.shipmentId});

  @override
  State<P2pHandoffScreen> createState() => _P2pHandoffScreenState();
}

class _P2pHandoffScreenState extends State<P2pHandoffScreen> {
  late final P2pShipmentBloc _bloc;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  bool _handoffInitiated = false;

  @override
  void initState() {
    super.initState();
    _bloc = P2pShipmentBloc(
      repository: GetIt.instance<P2pShipmentRepository>(),
    );
    _initiateHandoff();
    // Navigate immediately if the backend pushes a pickup-confirmed event.
    _socketSub = GetIt.instance<SocketClient>().p2pStatusUpdates.listen((data) {
      final status = (data['status'] as String?)?.toUpperCase();
      if (status == 'IN_TRANSIT' || data['type'] == 'p2p_pickup_confirmed') {
        _navigateToTracking();
      }
    });
  }

  void _initiateHandoff() {
    _bloc.add(P2pShipmentHandoffRequested(widget.shipmentId));
    _handoffInitiated = true;
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _bloc.add(P2pShipmentDetailRequested(widget.shipmentId));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _navigateToTracking() {
    _stopPolling();
    context.pushReplacement('/p2p/shipment/${widget.shipmentId}/tracking');
  }

  @override
  void dispose() {
    _stopPolling();
    _socketSub?.cancel();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<P2pShipmentBloc, P2pShipmentState>(
        listener: (context, state) {
          if (state.status == P2pShipmentStatus.failure && _handoffInitiated) {
            // Handoff may already be HANDOFF_PENDING — fall back to a detail fetch
            _handoffInitiated = false;
            _bloc.add(
                P2pShipmentDetailRequested(widget.shipmentId));
          }
          if (state.selectedRequest != null) {
            final s = state.selectedRequest!.status;
            if (s == ShipmentRequestStatus.handoffPending &&
                _pollTimer == null) {
              _startPolling();
            }
            if (s == ShipmentRequestStatus.inTransit) {
              _navigateToTracking();
            }
          }
        },
        builder: (context, state) {
          final shipment = state.selectedRequest;
          final code = shipment?.pickupConfirmationCode;
          final isLoading =
              state.status == P2pShipmentStatus.loading && shipment == null;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              title: const Text('Handoff Code'),
              leading: const BackButton(),
            ),
            body: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor))
                : _Body(
                    shipment: shipment,
                    code: code,
                    onOpenChat: () {
                      final chatId =
                          shipment?.chatThreadId ?? widget.shipmentId;
                      context.push('/chat/$chatId',
                          extra: 'Courier Chat');
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final P2pShipmentRequest? shipment;
  final String? code;
  final VoidCallback onOpenChat;

  const _Body({
    required this.shipment,
    required this.code,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon ─────────────────────────────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.handshake_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Hand Off Your Shipment',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Share this 6-digit code with your courier '
            'when you meet to hand over the package.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // ── Confirmation code ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.primaryColor.withAlpha(60), width: 1.5),
            ),
            child: code != null
                ? Column(
                    children: [
                      Text(
                        'Pickup Confirmation Code',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        code!,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          letterSpacing: 8,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const CircularProgressIndicator(
                          color: AppTheme.primaryColor, strokeWidth: 2.5),
                      const SizedBox(height: 12),
                      Text(
                        'Generating code…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // ── Copy button ───────────────────────────────────────────────────
          if (code != null)
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

          const SizedBox(height: 32),

          // ── Warning ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Only share this code when you physically hand over your '
                    'package. The courier will enter it to confirm receipt. '
                    'Your shipment will automatically move to "In Transit" '
                    'once the code is verified.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange[800],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Open Chat ─────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onOpenChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text(
                'Open Chat with Courier',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Waiting for the courier to confirm receipt…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
