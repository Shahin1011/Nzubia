import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';
import 'package:customer_nzubia_global/core/widgets/glass_container.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colors = theme.extension<AppColorsExtension>();
    
    final isPayout = transaction['type'] == 'PAYOUT_SENT';
    final isEscrowHold = transaction['type'] == 'ESCROW_HOLD';
    final isEscrowRelease = transaction['type'] == 'ESCROW_RELEASE';
    
    final List<String> urls = [];
    if (transaction['payout_proof_urls'] != null && transaction['payout_proof_urls'] is List) {
      urls.addAll((transaction['payout_proof_urls'] as List).map((e) => e.toString()));
    } else if (transaction['payout_proof_url'] != null) {
      urls.add(transaction['payout_proof_url'].toString());
    }

    String typeLabel = transaction['type'].toString();
    if (isPayout) {
      typeLabel = l10n.payout ?? 'Payout';
    } else if (isEscrowHold) typeLabel = l10n.escrowHold ?? 'Escrow Hold';
    else if (isEscrowRelease) typeLabel = l10n.escrowRelease ?? 'Escrow Release';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionDetails ?? 'Transaction Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Card
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isPayout 
                        ? Colors.orange.withValues(alpha: 0.1)
                        : (colors?.neonLime ?? Colors.green).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPayout ? Icons.arrow_upward : Icons.arrow_downward, 
                      color: isPayout ? Colors.orange : (colors?.neonLime ?? Colors.green), 
                      size: 32
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${isPayout ? '-' : '+'}\$${transaction['amount']}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isPayout ? Colors.orange : (colors?.neonLime ?? Colors.green),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMMd().add_jm().format(DateTime.parse(transaction['created_at'])),
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Details List
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(context, l10n.transactionId ?? 'Transaction ID', transaction['id']),
                  const Divider(height: 24),
                  _buildDetailRow(context, l10n.statusLabel ?? 'Status', transaction['status']),
                  if (transaction['description'] != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(context, l10n.description ?? 'Description', transaction['description']),
                  ],
                  if (transaction['notes'] != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(context, 'Notes', transaction['notes']),
                  ],
                  if (transaction['shipment'] != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context, 
                      'Shipment', 
                      transaction['shipment']['tracking_number'] ?? 'N/A'
                    ),
                  ],
                ],
              ),
            ),
            
            if (urls.isNotEmpty) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.payoutProofTitle ?? 'Proof of Payment:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () => _showImagePreview(context, urls[i]),
                      child: Container(
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(urls[i]),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: theme.dividerColor),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
