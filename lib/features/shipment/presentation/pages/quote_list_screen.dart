import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/quote_list/quote_list_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/quote_list/quote_list_event.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/quote_list/quote_list_state.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/quote_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/payment/domain/repositories/payment_repository.dart';
import 'package:customer_nzubia_global/core/widgets/user_avatar.dart';

class QuoteListScreen extends StatefulWidget {
  final String? shipmentId;
  final ShipmentEntity? shipment;

  const QuoteListScreen({super.key, this.shipmentId, this.shipment});

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuoteListBloc(quoteRepository: sl())..add(LoadQuotes(widget.shipmentId)),
      child: QuoteListView(isMainTab: widget.shipmentId == null, shipment: widget.shipment),
    );
  }
}

class QuoteListView extends StatefulWidget {
  final bool isMainTab;
  final ShipmentEntity? shipment;
  const QuoteListView({super.key, this.isMainTab = false, this.shipment});

  @override
  State<QuoteListView> createState() => _QuoteListViewState();
}

class _QuoteListViewState extends State<QuoteListView> {
  String _sortBy = 'price_asc'; // price_asc, rating_desc
  bool _isProcessingPayment = false;

  Future<void> _processPayment(BuildContext context, QuoteEntity quote) async {
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing payment...')),
      );

      final successUrl = kIsWeb
          ? '${Uri.base.origin}/payment/success'
          : 'nzubia://payment/success';
      final cancelUrl = kIsWeb
          ? '${Uri.base.origin}/payment/cancel'
          : 'nzubia://payment/cancel';

      final url = await sl<PaymentRepository>().createCheckoutSession(
        quoteId: quote.id,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch payment URL';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes Marketplace'),
        leading: widget.isMainTab ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'rating_desc', child: Text('Rating: High to Low')),
            ],
          ),
        ],
      ),
      body: BlocConsumer<QuoteListBloc, QuoteListState>(
        listener: (context, state) {
           if (state.status == QuoteListStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error loading quotes')),
            );
          }
           if (state.status == QuoteListStatus.quoteAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quote Accepted! Proceeding to Payment...')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == QuoteListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.quotes.isEmpty && state.status == QuoteListStatus.success) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/world_shipment.json',
                    height: 200,
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No quotes available yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Request a shipment to start receiving offers',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Sorting Logic
          List<QuoteEntity> displayQuotes = List.from(state.quotes);
          if (_sortBy == 'price_asc') {
            displayQuotes.sort((a, b) => a.amount.compareTo(b.amount));
          } else if (_sortBy == 'rating_desc') {
            displayQuotes.sort((a, b) => b.rating.compareTo(a.rating));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayQuotes.length,
            itemBuilder: (context, index) {
              final quote = displayQuotes[index];
              return _QuoteCard(
                quote: quote,
                isActionEnabled: widget.shipment == null || 
                                 ['PENDING_AGENTS', 'BIDDING_ACTIVE', 'QUOTED'].contains(widget.shipment!.status),
                onAccept: () => _processPayment(context, quote),
              );
            },
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final QuoteEntity quote;
  final VoidCallback onAccept;
  final bool isActionEnabled;

  const _QuoteCard({required this.quote, required this.onAccept, this.isActionEnabled = true});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final isAgentRole = user?.role == 'AGENT';
    final currencyFormat = NumberFormat.simpleCurrency(name: quote.currency);
    final dateFormat = DateFormat('MMM d, y');

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
                       if (quote.insuranceIncluded)
                         Padding(
                           padding: const EdgeInsets.only(top: 4.0),
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: Colors.green.shade50,
                               borderRadius: BorderRadius.circular(4),
                               border: Border.all(color: Colors.green.shade200),
                             ),
                             child: const Text('Insurance Included', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                           ),
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
                         color: AppTheme.primaryColor,
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

            const SizedBox(height: 12),
            // Dynamic Breakdown Area
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (isAgentRole) ...[
                    _buildSmallBreakdownRow(
                      context,
                      'Base Quote', 
                      currencyFormat.format(quote.breakdown?['base_charge'] ?? 0),
                    ),
                    const SizedBox(height: 4),
                    _buildSmallBreakdownRow(
                      context,
                      'Platform Fee', 
                      currencyFormat.format(quote.breakdown?['platform_fee'] ?? 0),
                      color: Colors.orange.shade700,
                    ),
                  ] else ...[
                    _buildSmallBreakdownRow(
                      context,
                      'Shipping Cost', 
                      currencyFormat.format((quote.breakdown?['base_charge'] ?? 0) + (quote.breakdown?['platform_fee'] ?? 0) + (quote.breakdown?['customs_fee'] ?? 0)),
                      color: Colors.orange.shade700,
                    ),
                  ],
                  if (quote.insuranceType != null && quote.insuranceType != 'NONE') ...[
                    const SizedBox(height: 4),
                    _buildSmallBreakdownRow(
                      context,
                      'Insurance (${quote.insuranceType == 'NZUBIA' ? 'Nzubia' : 'Private'})',
                      currencyFormat.format(quote.breakdown?['insurance_fee'] ?? 0),
                      color: Colors.orange.shade700,
                    ),
                  ],
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),

            // Action Buttons
            if (isActionEnabled)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Start Chat with Agent logic
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
                    onPressed: () => _showQuoteDetails(context, quote),
                    style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.primaryColor,
                       foregroundColor: Colors.white,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(AppLocalizations.of(context)!.viewOffer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBreakdownRow(BuildContext context, String label, String value, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? (isDark ? Colors.white : Colors.grey[800]))),
      ],
    );
  }

  void _showQuoteDetails(BuildContext context, QuoteEntity quote) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final dateFormat = DateFormat('EEEE, MMMM d, y');
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

              // Summary Section
              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.local_shipping,
                      label: 'Method',
                      value: quote.shippingMethod?.toUpperCase() ?? 'AIR',
                      iconColor: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.calendar_today,
                      label: 'Est. Delivery',
                      value: DateFormat('MMM d').format(quote.estimatedDeliveryDate),
                      iconColor: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Agent info section
              Row(
                children: [
                  UserAvatar(imageUrl: quote.agentProfileUrl, name: quote.agentName, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quote.agentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rated ${quote.rating.toStringAsFixed(1)} ★ (${quote.reviewCount} reviews)', 
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Cost Breakdown for Customer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light 
                    ? Colors.grey.shade50 
                    : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light 
                      ? Colors.grey.shade200 
                      : Colors.grey.shade800
                  ),
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
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
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

              const SizedBox(height: 32),
              
              Text('Agent Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
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

              const SizedBox(height: 48),
              
              if (isActionEnabled)
                ElevatedButton(
                  onPressed: () => context.pop(true),
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
    ).then((accepted) {
      if (accepted == true) {
        onAccept();
      }
    });
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

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _DetailItem({required this.icon, required this.label, required this.value, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        )
      ],
    );
  }
}
