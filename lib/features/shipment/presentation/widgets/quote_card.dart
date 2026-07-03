import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/quote_entity.dart';
import 'package:customer_nzubia_global/core/widgets/user_avatar.dart';

class QuoteCard extends StatelessWidget {
  final QuoteEntity quote;
  final Future<void> Function() onAccept;

  const QuoteCard({super.key, required this.quote, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: quote.currency);
    final dateFormat = DateFormat('MMM d, y');
    final isAccepted = quote.status == 'ACCEPTED';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header: Agent Info & Rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 UserAvatar(
                   imageUrl: quote.agentProfileUrl,
                   name: quote.agentName,
                   radius: 24,
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         quote.agentName,
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                       Row(
                         children: [
                           const Icon(Icons.star, size: 14, color: Colors.amber),
                           const SizedBox(width: 4),
                           Text(
                             '${quote.rating.toStringAsFixed(1)} (${quote.reviewCount})',
                             style: TextStyle(color: Colors.grey[600], fontSize: 12),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),

                 // Price
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Text(
                       currencyFormat.format(quote.amount),
                       style: TextStyle(
                         color: isAccepted ? Colors.green : AppTheme.primaryColor,
                         fontWeight: FontWeight.bold,
                         fontSize: 18,
                       ),
                     ),
                     Text(
                       'Est. Delivery',
                       style: TextStyle(color: Colors.grey[500], fontSize: 10),
                     ),
                     Text(
                       dateFormat.format(quote.estimatedDeliveryData),
                       style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                     ),
                   ],
                 ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),

            // Action Buttons
            if (!isAccepted)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.push('/chat/${quote.agentId}', extra: quote.agentName);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(AppLocalizations.of(context)!.chat),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showQuoteDetails(context),
                      style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.primaryColor,
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(AppLocalizations.of(context)!.viewOffer),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'QUOTE ACCEPTED',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuoteDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final currencyFormat = NumberFormat.simpleCurrency(name: quote.currency);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Logic to hide platform fees
        final breakdown = quote.breakdown;
        double shippingCost = quote.amount;
        double insuranceFee = 0;
        String insuranceDisplay = 'None';

        if (breakdown != null) {
           final base = (breakdown['base_charge'] ?? 0).toDouble();
           final platform = (breakdown['platform_fee'] ?? 0).toDouble();
           final customs = (breakdown['customs_fee'] ?? 0).toDouble();
           insuranceFee = (breakdown['insurance_fee'] ?? 0).toDouble();
           
           // Combined shipping cost: Base + Platform + Customs
           shippingCost = base + platform + customs;
        }

        if (quote.insuranceType == 'NZUBIA') {
          insuranceDisplay = 'Nzubia Platform Insurance';
        } else if (quote.insuranceType == 'PRIVATE') {
          insuranceDisplay = quote.insuranceName ?? 'Private Insurance';
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Offer Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Agent Info
              Row(
                children: [
                  UserAvatar(imageUrl: quote.agentProfileUrl, name: quote.agentName, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quote.agentName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        Text('Rated ${quote.rating.toStringAsFixed(1)} ★ (${quote.reviewCount} reviews)', 
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Cost Breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBreakdownRow(context, 'Shipping Cost', currencyFormat.format(shippingCost)),
                    if (insuranceFee > 0) ...[
                      const SizedBox(height: 12),
                      _buildBreakdownRow(context, 'Insurance ($insuranceDisplay)', currencyFormat.format(insuranceFee)),
                      const SizedBox(height: 8),
                      Text(
                        '* Insurance is included in the total shipping cost',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    _buildBreakdownRow(
                      context,
                      'Total Amount', 
                      currencyFormat.format(quote.amount),
                      isTotal: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('Agent Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quote.notes.isNotEmpty ? quote.notes : 'No specific notes provided.',
                  style: TextStyle(height: 1.5, color: isDark ? Colors.white : Colors.black87),
                ),
              ),

              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () async {
                    Navigator.pop(context); // Close sheet
                    await onAccept();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(AppLocalizations.of(context)!.acceptAndPay, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreakdownRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
            color: isTotal 
                ? (isDark ? Colors.white : Colors.black) 
                : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
            color: isTotal 
                ? AppTheme.primaryColor 
                : (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}
