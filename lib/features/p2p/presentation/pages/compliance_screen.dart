import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_waiver.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/compliance/p2p_compliance_bloc.dart';

/// Compliance Centre. Accepts an optional `shipmentId` query param: when
/// present the screen also fetches a waiver preview and lets the user accept
/// it for that specific shipment. Without it, only the platform rules and
/// restricted items list are shown.
class P2pComplianceScreen extends StatelessWidget {
  const P2pComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shipmentId =
        GoRouterState.of(context).uri.queryParameters['shipmentId'];
    return BlocProvider(
      create: (_) {
        final bloc = GetIt.instance<P2pComplianceBloc>()
          ..add(const P2pComplianceLoadRequested());
        if (shipmentId != null && shipmentId.isNotEmpty) {
          bloc.add(P2pComplianceWaiverPreviewRequested(shipmentId));
        }
        return bloc;
      },
      child: _ComplianceCentreView(shipmentId: shipmentId),
    );
  }
}

class _ComplianceCentreView extends StatelessWidget {
  final String? shipmentId;
  const _ComplianceCentreView({this.shipmentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Compliance Centre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context
                .read<P2pComplianceBloc>()
                .add(const P2pComplianceLoadRequested()),
          ),
        ],
      ),
      body: BlocBuilder<P2pComplianceBloc, P2pComplianceState>(
        builder: (context, state) {
          switch (state.status) {
            case P2pComplianceStatus.initial:
            case P2pComplianceStatus.loading:
              if (state.rules == null) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryColor),
                );
              }
              return _ComplianceBody(state: state);

            case P2pComplianceStatus.failure:
              return _ErrorState(
                message: state.errorMessage ?? 'Failed to load compliance',
                onRetry: () => context
                    .read<P2pComplianceBloc>()
                    .add(const P2pComplianceLoadRequested()),
              );

            case P2pComplianceStatus.waiverPreview:
              return _WaiverPreviewView(
                preview: state.waiverPreview!,
                shipmentId: shipmentId!,
              );

            case P2pComplianceStatus.waiverAccepted:
            case P2pComplianceStatus.loaded:
              return _ComplianceBody(state: state);
          }
        },
      ),
    );
  }
}

// ─── Compliance body ──────────────────────────────────────────────────────────

class _ComplianceBody extends StatelessWidget {
  final P2pComplianceState state;

  const _ComplianceBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rules = state.rules;
    final restrictedItems = state.restrictedItems;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.status == P2pComplianceStatus.waiverAccepted)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 10),
                Text(
                  'Waiver accepted successfully',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Platform rules card
        if (rules != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(8), blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gavel_outlined,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Platform Rules',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _RuleRow(
                  label: 'Max weight per shipment',
                  value: '${rules.maxWeightKg.toStringAsFixed(0)} kg',
                ),
                _RuleRow(
                  label: 'Max declared value',
                  value:
                      '\$${rules.maxDeclaredValueUsd.toStringAsFixed(0)} USD',
                ),
                _RuleRow(
                  label: 'Default service radius',
                  value: '${rules.defaultRadiusKm.toStringAsFixed(0)} km',
                ),
                _RuleRow(
                  label: 'Platform fee',
                  value:
                      '${rules.platformFeePercent.toStringAsFixed(1)}%',
                ),
                _RuleRow(
                  label: 'Waiver version',
                  value: rules.waiverVersion,
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Restricted categories
        if (rules != null && rules.restrictedCategories.isNotEmpty) ...[
          Text(
            'Restricted Categories',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'These categories require special documentation and may be refused by some couriers.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: rules.restrictedCategories
                .map(
                  (cat) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Text(
                      cat,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Prohibited items
        Text(
          'Prohibited Items',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'The following items cannot be shipped under any circumstances.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 10),
        if (restrictedItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No prohibited items configured.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(6), blurRadius: 3),
              ],
            ),
            child: Column(
              children: restrictedItems
                  .asMap()
                  .entries
                  .map(
                    (e) => _ProhibitedTile(
                      label: e.value,
                      isLast: e.key == restrictedItems.length - 1,
                    ),
                  )
                  .toList(),
            ),
          ),

        const SizedBox(height: 20),

        // Customs warnings
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: Colors.amber[800], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Customs Warnings',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.amber[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._customsWarnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45))),
                      Expanded(
                        child: Text(
                          w,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  static const _customsWarnings = [
    'You are responsible for complying with all import and export regulations in each country on your route.',
    'Some countries have strict limits on the value of goods that can be imported duty-free. Exceeding these limits can result in seizure.',
    'Electronics, especially those containing lithium batteries, may require special airline approval.',
    'Food items and agricultural products may be prohibited at certain international borders.',
  ];
}

// ─── Waiver preview view ──────────────────────────────────────────────────────

class _WaiverPreviewView extends StatefulWidget {
  final P2pWaiverPreview preview;
  final String shipmentId;

  const _WaiverPreviewView({
    required this.preview,
    required this.shipmentId,
  });

  @override
  State<_WaiverPreviewView> createState() => _WaiverPreviewViewState();
}

class _WaiverPreviewViewState extends State<_WaiverPreviewView> {
  late final Set<String> _checked;

  @override
  void initState() {
    super.initState();
    _checked = <String>{};
  }

  bool get _allChecked =>
      widget.preview.rules.every((r) => _checked.contains(r.flag));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liability Waiver',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version ${widget.preview.termsVersion} · '
                  'Shipment ${widget.preview.shipmentId.substring(0, widget.preview.shipmentId.length.clamp(0, 8))}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    widget.preview.waiverText,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.5),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Acknowledgements',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...widget.preview.rules.map(
                  (rule) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppTheme.primaryColor,
                    value: _checked.contains(rule.flag),
                    onChanged: (val) => setState(() {
                      if (val ?? false) {
                        _checked.add(rule.flag);
                      } else {
                        _checked.remove(rule.flag);
                      }
                    }),
                    title: Text(
                      rule.title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      rule.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context
                      .read<P2pComplianceBloc>()
                      .add(const P2pComplianceLoadRequested()),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _allChecked
                      ? () => context.read<P2pComplianceBloc>().add(
                            P2pComplianceWaiverAccepted(
                              shipmentRequestId: widget.shipmentId,
                              acknowledgedFlags: _checked.toList(),
                            ),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                  child: const Text('Accept Waiver'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Smaller widgets ──────────────────────────────────────────────────────────

class _RuleRow extends StatelessWidget {
  final String label;
  final String value;

  const _RuleRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProhibitedTile extends StatelessWidget {
  final String label;
  final bool isLast;

  const _ProhibitedTile({required this.label, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text('🚫', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.block_outlined,
                  size: 16, color: Colors.red[600]),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: theme.colorScheme.outline.withValues(alpha: 0.4)),
      ],
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
            Icon(Icons.warning_amber_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Could not load compliance information',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
