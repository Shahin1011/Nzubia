import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bidding/bidding_bloc.dart';
import '../bloc/bidding/bidding_state.dart';
import '../bloc/bidding/bidding_event.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/quote_entity.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';

class BiddingDashboardScreen extends StatefulWidget {
  final String shipmentId;

  const BiddingDashboardScreen({super.key, required this.shipmentId});

  @override
  State<BiddingDashboardScreen> createState() => _BiddingDashboardScreenState();
}

class _BiddingDashboardScreenState extends State<BiddingDashboardScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<QuoteEntity> _quotes = [];

  @override
  void initState() {
    super.initState();
    context.read<BiddingBloc>().add(StartWatchingQuotes(widget.shipmentId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.liveBids)),
      body: BlocConsumer<BiddingBloc, BiddingState>(
        listener: (context, state) {
          if (state is BiddingActive) {
            // Handle Animated List updates
            // Simple diffing for MVP: If length increases, insert top
            if (state.quotes.length > _quotes.length) {
              final newCount = state.quotes.length - _quotes.length;
              for (int i = 0; i < newCount; i++) {
                 _listKey.currentState?.insertItem(0);
              }
            }
             _quotes = state.quotes;
          } else if (state is BiddingLockedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.quoteAcceptedShipmentLocked)),
            );
            // Navigate away
            Navigator.pop(context);
          } else if (state is BiddingError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is BiddingInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BiddingActive || state is BiddingLocking) {
             // Show list even if locking
             if (_quotes.isEmpty) {
                return Center(child: Text(AppLocalizations.of(context)!.waitingForAgents));
             }

             return AnimatedList(
               key: _listKey,
               initialItemCount: _quotes.length,
               itemBuilder: (context, index, animation) {
                 final quote = _quotes[index];
                 return SlideTransition(
                   position: animation.drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
                   child: Card(
                     margin: const EdgeInsets.all(8),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     child: Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             children: [
                               CircleAvatar(
                                 backgroundImage: quote.agentProfileUrl != null ? NetworkImage(quote.agentProfileUrl!) : null,
                                 child: quote.agentProfileUrl == null ? const Icon(Icons.person) : null,
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(quote.agentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                     Row(
                                       children: [
                                         const Icon(Icons.star, color: Colors.amber, size: 16),
                                         const SizedBox(width: 4),
                                         Text('${quote.rating ?? 0.0} (${quote.reviewCount ?? 0} reviews)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                       ],
                                     ),
                                   ],
                                 ),
                               ),
                               IconButton(
                                 icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                                 onPressed: () => context.push('/chat/${quote.agentId}', extra: quote.agentName),
                                 tooltip: 'Chat with Agent',
                               ),
                             ],
                           ),
                           const Divider(height: 24),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text('\$${quote.amount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                                   Text('${quote.shippingMethod} • ETA: ${DateFormat.MMMd().format(quote.estimatedDeliveryDate)}', style: const TextStyle(color: Colors.grey)),
                                 ],
                               ),
                               ElevatedButton(
                                 onPressed: state is BiddingLocking
                                   ? null
                                   : () => context.read<BiddingBloc>().add(AcceptQuote(quote.id)),
                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                 child: state is BiddingLocking && index == 0 // Only show spinner on active one if possible, or blocking all
                                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                   : Text(AppLocalizations.of(context)!.acceptQuote),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),
                 );
               },
             );
          }

          return Center(child: Text(AppLocalizations.of(context)!.connecting));
        },
      ),
    );
  }
}
