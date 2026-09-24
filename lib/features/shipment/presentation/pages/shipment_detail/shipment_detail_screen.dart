import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_nzubia_global/features/auth/domain/entities/user_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/cargo_item_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/shipment_repository.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_event.dart';
import 'package:customer_nzubia_global/core/widgets/user_avatar.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/shipment_detail/edit_manifest_screen.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/quote_entity.dart';
import 'package:customer_nzubia_global/features/payment/domain/repositories/payment_repository.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:customer_nzubia_global/features/shipment/presentation/widgets/tracking_code_widget.dart';
import 'package:customer_nzubia_global/features/dashboard/presentation/widgets/review_dialog.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/shipment_detail/cargo_item_detail_screen.dart';
import 'package:customer_nzubia_global/core/services/agent_status_update_service.dart';
import 'package:customer_nzubia_global/core/widgets/update_status_button.dart';
import 'package:customer_nzubia_global/core/network/socket_client.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final ShipmentEntity shipment;

  const ShipmentDetailScreen({super.key, required this.shipment});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  UserEntity? _assignedAgent;
  bool _isLoadingAgent = false;
  bool _isLoadingShipment = false;
  late ShipmentEntity _shipment;
  int _docTab = 0; // 0: Photos, 1: Documents
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _shipment = widget.shipment;
    _fetchShipmentDetails();
    _initSocketListener();
  }

  void _initSocketListener() {
    _socketSubscription = sl<SocketClient>().shipmentUpdates.listen((event) {
      if (event['shipmentId'] == _shipment.id) {
        debugPrint('Real-time update received for shipment ${_shipment.id}');
        _fetchShipmentDetails();
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchShipmentDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingShipment = true);
    try {
      final fullShipment = await sl<ShipmentRepository>().getShipment(_shipment.id);
      
      bool needsRefresh = false;
      for (var payment in fullShipment.payments) {
        if (payment.status == 'PENDING') {
          try {
            await sl<PaymentRepository>().syncPayment(payment.id);
            needsRefresh = true;
          } catch (_) {}
        }
      }
      
      final finalShipment = needsRefresh 
          ? await sl<ShipmentRepository>().getShipment(_shipment.id) 
          : fullShipment;

      if (mounted) {
        setState(() {
          _shipment = finalShipment;
          _isLoadingShipment = false;
        });

        if (_shipment.agentId != null) {
          _fetchAgentDetails(_shipment.agentId!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingShipment = false);
        _handleError(context, e, _fetchShipmentDetails);
      }
    }
  }

  Future<void> _fetchAgentDetails(String agentId) async {
    setState(() => _isLoadingAgent = true);
    try {
      final agent = await sl<AuthRepository>().getUserById(agentId);
      if (mounted) {
        setState(() {
          _assignedAgent = agent;
          _isLoadingAgent = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAgent = false);
    }
  }

  void _handleError(BuildContext context, dynamic error, VoidCallback onRetry) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.error is SocketException) {
        _showNoInternetDialog(context, onRetry);
        return;
      }

      if (error.response?.statusCode == 400) {
        final message = error.response?.data['message'];
        String userFriendlyMessage = 'Invalid request.';
        
        if (message != null) {
          final msgStr = message.toString();
          if (msgStr.contains('Invalid Pickup PIN')) {
            userFriendlyMessage = 'Incorrect PIN. Please ask the customer for the correct 6-digit PIN.';
          } else if (msgStr.contains('reach \'PICKED_UP\'')) {
            userFriendlyMessage = 'Complete pickup verification first (PIN + 3 photos).';
          } else if (msgStr.contains('3 condition photos')) {
            userFriendlyMessage = '3 condition photos are required for pickup.';
          } else if (msgStr.contains('Linear Progression Violation')) {
            userFriendlyMessage = msgStr;
          } else {
            userFriendlyMessage = msgStr;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userFriendlyMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
          backgroundColor: Colors.red[700]
        ));
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error: $error', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.red[700],
    ));
  }

  void _showNoInternetDialog(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text('Please check your connection and try again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); onRetry(); }, child: const Text('Reload')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shipmentDetails)),
      body: _isLoadingShipment
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(),
                  _buildCustomerPinSection(),
                  const SizedBox(height: 16),
                  if (_isAssignedAgent) _buildAgentActions(),
                  if (['PENDING_AGENTS', 'BIDDING_ACTIVE', 'REQUESTED'].contains(_shipment.status)) _buildQuotesButton(),
                  if (_shipment.trackingNumber != null) ...[
                    _buildTrackingCodeSection(),
                    const Divider(height: 48),
                  ],
                  Text(l10n.route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _buildRouteStep(Icons.circle, Colors.green, l10n.origin, _shipment.originAddress),
                  _buildRouteDivider(),
                  _buildRouteStep(Icons.location_on, Colors.red, l10n.destination, _shipment.destinationAddress),
                  const SizedBox(height: 24),
                  _buildInsuranceSection(),
                  const SizedBox(height: 24),
                  _buildDocumentsGallery(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (_isAgentRole) _buildCustomerDetails(), 
                  if (_shipment.recipient != null) _buildRecipientDetails(),
                  // _buildQuotesSection(),
                  _buildPaymentHistorySection(),
                  _buildCargoManifest(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (_shipment.agentId != null) _buildAgentSection(_shipment.agentId!),
                  if (_shipment.events.isNotEmpty) _buildTrackingHistory(),
                  const SizedBox(height: 24),
                  if (_canLeaveReview)
                     Container(
                       width: double.infinity,
                       margin: const EdgeInsets.only(bottom: 24),
                       child: ElevatedButton.icon(
                         onPressed: () => _showReviewDialog(context),
                         icon: const Icon(Icons.star, color: Colors.white),
                         label: Text(l10n.rateReviewAgent, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                       ),
                     ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildRouteDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 11),
      height: 30,
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.grey, width: 2))),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _getStatusColor(_shipment.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(_shipment.status)),
      ),
      child: Column(
        children: [
          Text(_getLocalizedStatus(_shipment.status).toUpperCase(), style: TextStyle(color: _getStatusColor(_shipment.status), fontWeight: FontWeight.bold, fontSize: 20)),
          Text('${AppLocalizations.of(context)!.service}: ${_shipment.serviceLevel.replaceAll('_', ' ')}'),
        ],
      ),
    );
  }

  Widget _buildCustomerPinSection() {
    if (_isAgentRole || !['BOOKED', 'READY_FOR_PICKUP'].contains(_shipment.status) || _shipment.pickupPin == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
      child: Column(
        children: [
          const Text('PICKUP VERIFICATION PIN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 12),
          Text(_shipment.pickupPin!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.orange)),
          const SizedBox(height: 8),
          const Text('Give this PIN to the agent at pickup.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAgentActions() {
    if (_shipment.status == 'DELIVERED') return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: UpdateStatusButton(
        shipment: _shipment, 
        onRefresh: _fetchShipmentDetails,
      ),
    );
  }

  Widget _buildQuotesButton() {
    final user = context.read<AuthBloc>().state.user;
    final isAgent = user?.role.toUpperCase() == 'AGENT';
    final hasQuoted = _shipment.quotes.any((q) => q.agentId == user?.id);
    final quoteCount = _shipment.quotes.length;

    if (isAgent) {
      if (!hasQuoted && ['PENDING_AGENTS', 'BIDDING_ACTIVE'].contains(_shipment.status)) {
        final isLimitReached = quoteCount >= 3;
        
        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton.icon(
                onPressed: isLimitReached ? null : () => context.push('/agent/quote/create', extra: _shipment),
                icon: Icon(isLimitReached ? Icons.lock : Icons.add_circle),
                label: Text(isLimitReached 
                  ? AppLocalizations.of(context)!.maximumQuotesReached 
                  : AppLocalizations.of(context)!.submitQuote),
                style: isLimitReached ? ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.grey.shade600,
                ) : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                AppLocalizations.of(context)!.quotesCount(quoteCount),
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  color: isLimitReached ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/shipment/${_shipment.id}/quotes', extra: _shipment),
        icon: const Icon(Icons.request_quote),
        label: Text(AppLocalizations.of(context)!.viewQuotesBids),
      ),
    );
  }

  Widget _buildTrackingCodeSection() {
    return TrackingCodeWidget(trackingNumber: _shipment.trackingNumber!);
  }

  Widget _buildRouteStep(IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(address, style: const TextStyle(fontSize: 16)),
        ])),
      ],
    );
  }

  Widget _buildInsuranceSection() {
    final hasData = _shipment.totalItemValue > 0 || _shipment.insuranceRequested;
    if (!hasData) return const SizedBox.shrink();
    
    QuoteEntity? active;
    try { active = _shipment.quotes.firstWhere((q) => q.status == 'ACCEPTED'); } catch(_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Value & Insurance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
          child: Column(
            children: [
              _buildSimpleRow('Item Value:', '\$${_shipment.totalItemValue.toStringAsFixed(2)}'),
              const Divider(height: 24),
              _buildSimpleRow('Insurance Status:', _shipment.insuranceRequested ? 'REQUESTED' : 'NOT REQUESTED'),
              if (active != null && active.insuranceType != 'NONE') ...[
                const SizedBox(height: 8),
                _buildSimpleRow('Provider:', active.insuranceType == 'NZUBIA' ? 'Nzubia Platform' : (active.insuranceName ?? 'Agent')),
                _buildSimpleRow('Fee:', '\$${(active.breakdown?['insurance_fee'] ?? 0).toDouble().toStringAsFixed(2)}'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildDocumentsGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Proof & Paperwork', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          if (_docTab == 1 && _isAllowedToUpload) IconButton(onPressed: _showUploadDocOptions, icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor)),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [_buildSmallTab('Photos', 0), _buildSmallTab('Docs', 1)]),
          ),
        ]),
        const SizedBox(height: 16),
        _docTab == 0 ? _buildPhotoGallery() : _buildDocumentList(),
      ],
    );
  }

  bool get _isAllowedToUpload {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return false;
    if (user.role == 'ADMIN') return true;
    if (user.id == _shipment.customerId) return true;
    if (user.id == _shipment.agentId) return true;
    return false;
  }

  Widget _buildSmallTab(String label, int index) {
    final isSelected = _docTab == index;
    return GestureDetector(
      onTap: () => setState(() => _docTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primaryColor : Colors.grey)),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    final p = _shipment.pickupImages;
    final d = _shipment.podImages;
    if (p.isEmpty && d.isEmpty) return const Text('No photos yet', style: TextStyle(color: Colors.grey));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (p.isNotEmpty) ...[const Text('Pickup Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 8), SizedBox(height: 80, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: p.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => _buildThumbnail(p[i])))],
      if (d.isNotEmpty) ...[const SizedBox(height: 16), const Text('Delivery Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 8), SizedBox(height: 80, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: d.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => _buildThumbnail(d[i])))],
    ]);
  }

  Widget _buildThumbnail(String url) {
    return GestureDetector(
      onTap: () => _showImagePreview(context, url),
      child: Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover))),
    );
  }

  Widget _buildDocumentList() {
    final docs = _shipment.documents;
    if (docs.isEmpty) return const Text('No documents uploaded');
    return Column(children: docs.map((doc) => Card(
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text(doc['type']?.toString().replaceAll('_', ' ') ?? 'Document'),
        subtitle: Text('Uploaded ${DateFormat('MMM d, y').format(DateTime.parse(doc['uploaded_at']))}'),
        trailing: IconButton(icon: const Icon(Icons.download), onPressed: () => url_launcher.launchUrl(Uri.parse(doc['url']))),
      ),
    )).toList());
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.black, child: Stack(children: [
      InteractiveViewer(child: Center(child: Image.network(url))),
      Positioned(top: 10, right: 10, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
    ])));
  }

  Widget _buildCustomerDetails() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.senderCustomerDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person),
        title: Text(AppLocalizations.of(context)!.customer),
        subtitle: Text(_shipment.customerId),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.assignment_late_outlined, color: Colors.orange), onPressed: () => _showRequestInfoDialog(context, _shipment.id)),
            IconButton(icon: const Icon(Icons.chat, color: AppTheme.primaryColor), onPressed: () => _handleCustomerChat(_shipment.customerId)),
          ],
        ),
      ),
      const Divider(),
    ]);
  }

  Widget _buildRecipientDetails() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.recipientDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person_outline),
        title: Text(_shipment.recipient?.name ?? 'N/A'),
        subtitle: Text(_shipment.recipient?.address ?? ''),
        trailing: IconButton(icon: const Icon(Icons.chat, color: AppTheme.primaryColor), onPressed: _handleRecipientChat),
      ),
      const Divider(),
    ]);
  }

  // Widget _buildQuotesSection() {
  //   final user = context.read<AuthBloc>().state.user;
  //   final isAgent = user?.role == 'AGENT';
  //   final displayed = isAgent ? _shipment.quotes.where((q) => q.agentId == user?.id).toList() : _shipment.quotes;
  //   if (displayed.isEmpty) return const SizedBox.shrink();
  //
  //   return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //     Text(AppLocalizations.of(context)!.quotesAndBids, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  //     const SizedBox(height: 12),
  //     ...displayed.map((q) => _buildQuoteCard(q)).toList(),
  //     const Divider(),
  //   ]);
  // }

  // Widget _buildQuoteCard(QuoteEntity quote) {
  //   final isAccepted = quote.status == 'ACCEPTED';
  //   final isAnyQuoteAccepted = _shipment.quotes.any((q) => q.status == 'ACCEPTED');
  //   final currentUserId = context.read<AuthBloc>().state.user?.id;
  //   final isMyQuote = currentUserId != null && quote.agentId == currentUserId;
  //
  //   return Card(
  //     elevation: 0,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isAccepted ? Colors.green : Colors.grey.shade200)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         children: [
  //           Row(children: [
  //             UserAvatar(imageUrl: quote.agentProfileUrl, name: quote.agentName, radius: 20),
  //             const SizedBox(width: 12),
  //             Expanded(child: Text(quote.agentName, style: const TextStyle(fontWeight: FontWeight.bold))),
  //             IconButton(icon: const Icon(Icons.chat, color: AppTheme.primaryColor), onPressed: () => context.push('/chat/${quote.agentId}', extra: quote.agentName)),
  //           ]),
  //           Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
  //             Text('${quote.currency} ${quote.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
  //             if (isAccepted) const Chip(label: Text('ACCEPTED', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
  //             else if (quote.status == 'PENDING' && !isAnyQuoteAccepted && !_isAgentRole) ElevatedButton(onPressed: () => _processPayment(quote.id), child: Text(AppLocalizations.of(context)!.accept))
  //             else if (isMyQuote && quote.status == 'PENDING' && !isAnyQuoteAccepted && ['PENDING_AGENTS', 'BIDDING_ACTIVE'].contains(_shipment.status))
  //                 IconButton(
  //                   icon: const Icon(Icons.edit, color: Colors.blue),
  //                   onPressed: () => context.push('/agent/quote/create', extra: {'shipment': _shipment, 'quote': quote}),
  //                 ),
  //           ]),
  //
  //           // Breakdown Area
  //           const SizedBox(height: 12),
  //           Container(
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               color: Colors.grey.withOpacity(0.05),
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Column(
  //               children: [
  //                 if (_isAgentRole) ...[
  //                   // Agent sees everything
  //                   _buildSmallBreakdownRow(
  //                     'Base Quote',
  //                     '${quote.currency} ${(quote.breakdown?['base_charge'] ?? 0).toStringAsFixed(2)}'
  //                   ),
  //                   const SizedBox(height: 4),
  //                   _buildSmallBreakdownRow(
  //                     'Platform Fee',
  //                     '${quote.currency} ${(quote.breakdown?['platform_fee'] ?? 0).toStringAsFixed(2)}',
  //                     color: Colors.orange.shade700
  //                   ),
  //                 ] else ...[
  //                   // Customer sees combined Shipping Cost
  //                   _buildSmallBreakdownRow(
  //                     'Shipping Cost',
  //                     '${quote.currency} ${((quote.breakdown?['base_charge'] ?? 0) + (quote.breakdown?['platform_fee'] ?? 0) + (quote.breakdown?['customs_fee'] ?? 0)).toStringAsFixed(2)}'
  //                   ),
  //                 ],
  //
  //                 if (quote.insuranceType != null && quote.insuranceType != 'NONE') ...[
  //                   const SizedBox(height: 4),
  //                   _buildSmallBreakdownRow(
  //                     'Insurance (${quote.insuranceType == 'NZUBIA' ? 'Nzubia' : 'Private'})',
  //                     '${quote.currency} ${(quote.breakdown?['insurance_fee'] ?? 0).toStringAsFixed(2)}'
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),          ],
  //       ),
  //     ),
  //   );
  // }
  //
  // Widget _buildSmallBreakdownRow(String label, String value, {Color? color}) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
  //       Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? Colors.grey[800])),
  //     ],
  //   );
  // }

  // Future<void> _processPayment(String qid) async {
  //   try {
  //     final sUrl = kIsWeb ? '${Uri.base.origin}/payment/success' : 'nzubia://payment/success';
  //     final cUrl = kIsWeb ? '${Uri.base.origin}/payment/cancel' : 'nzubia://payment/cancel';
  //     final url = await sl<PaymentRepository>().createCheckoutSession(quoteId: qid, successUrl: sUrl, cancelUrl: cUrl);
  //     if (await url_launcher.canLaunchUrl(Uri.parse(url))) {
  //       await url_launcher.launchUrl(Uri.parse(url), mode: url_launcher.LaunchMode.externalApplication);
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
  //       backgroundColor: Colors.red[700],
  //     ));
  //   }
  // }

  Widget _buildPaymentHistorySection() {
    if (_shipment.payments.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.paymentHistory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ..._shipment.payments.map((p) => ListTile(title: Text('\$${p.amount}'), subtitle: Text(p.status))),
      const Divider(),
    ]);
  }

  Widget _buildCargoManifest() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.cargoManifest, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ..._shipment.cargoItems.map((item) => _buildCargoItem(item)),

    ]);
  }

  Widget _buildCargoItem(CargoItemEntity item) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.inventory_2),
        title: Text(item.description),
        subtitle: Text('${item.weight.toStringAsFixed(2)} lbs / ${(item.weight * 0.453592).toStringAsFixed(1)} kg • ${item.quantity} units'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CargoItemDetailScreen(item: item, shipment: _shipment))),
      ),
    );
  }

  Widget _buildAgentSection(String id) {
    String name = _assignedAgent?.businessName ?? _assignedAgent?.fullName ?? 'Agent';
    return ListTile(
      leading: UserAvatar(imageUrl: _assignedAgent?.profileImageUrl, name: name, radius: 20),
      title: Text(name),
      subtitle: const Text('Assigned Agent'),
      trailing: IconButton(icon: const Icon(Icons.chat), onPressed: () => context.push('/chat/$id', extra: name)),
    );
  }

  Widget _buildTrackingHistory() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppLocalizations.of(context)!.trackingHistory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      ..._shipment.events.map((e) => ListTile(
        dense: true,
        leading: Icon(Icons.check_circle, size: 16, color: _getStatusColor(e.status)),
        title: Text(_getLocalizedStatus(e.status), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${e.description}\n${DateFormat('MMM d, HH:mm').format(e.timestamp)} • ${e.actor ?? "System"}'),
      )),
    ]);
  }

  void _showUploadDocOptions() {
    final List<Map<String, String>> opts = _isAgentRole 
      ? [
          {'k': 'BILL_OF_LADING', 'l': 'Bill of Lading'}, 
          {'k': 'INSURANCE_CERTIFICATE', 'l': 'Insurance Certificate'}, 
          {'k': 'POD', 'l': 'Proof of Delivery (POD)'},
          {'k': 'PACKING_LIST', 'l': 'Packing List'},
          {'k': 'OTHER', 'l': 'Other Document'},
        ]
      : [
          {'k': 'COMMERCIAL_INVOICE', 'l': 'Commercial Invoice'}, 
          {'k': 'PACKING_LIST', 'l': 'Packing List'},
          {'k': 'OTHER', 'l': 'Other Document'},
        ];

    showModalBottomSheet(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: opts.map((o) => ListTile(
      title: Text(o['l']!),
      onTap: () async {
        Navigator.pop(ctx);
        final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
        if (res?.files.single.path != null) _uploadDoc(res!.files.single.path!, o['k']!);
      },
    )).toList()));
  }

  Future<void> _uploadDoc(String path, String type) async {
    try {
      await sl<ShipmentRepository>().uploadDocument(_shipment.id, path, type);
      _fetchShipmentDetails();
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red[700],
        ));
      }
    }  }

  void _showRequestInfoDialog(BuildContext context, String shipmentId) {
    final messageController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Request Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What information do you need from the customer?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'e.g. Please provide a clear photo of the invoice...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            const Text(
              'The customer will receive a notification and an email with your request.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final msg = messageController.text.trim();
              if (msg.isEmpty) return;
              
              Navigator.pop(context);
              try {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending request...')));
                await sl<ShipmentRepository>().requestInfo(shipmentId, msg);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Information request sent to customer')));
                  _fetchShipmentDetails(); 
                }
              } catch (e) {
                if (mounted) {
                  final errorMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.red[700],
                  ));
                }
              }            }, 
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Send Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCustomerChat(String id) async {
    final user = await sl<AuthRepository>().getUserById(id);
    if (user != null && mounted) context.push('/chat/${user.id}', extra: user.fullName);
  }

  Future<void> _handleRecipientChat() async {
    if (_shipment.recipient?.email != null) {
      final user = await sl<AuthRepository>().findUserByEmail(_shipment.recipient!.email);
      if (user != null && mounted) context.push('/chat/${user.id}', extra: user.fullName);
    }
  }

  bool get _canLeaveReview {
    if (_isAgentRole) return false;
    if (_shipment.status.toUpperCase() != 'DELIVERED' || _shipment.agentId == null) return false;
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return false;
    return !_shipment.reviews.any((r) => r.authorId == userId);
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReviewDialog(
        onSubmit: (rating, comment) async {
          try {
            await sl<ShipmentRepository>().submitReview(_shipment.id, rating.toInt(), comment);
            return true;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed: $e', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red[700],
            ));
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.reviewSubmitted)));
      _fetchShipmentDetails(); 
    }
  }

  String _getLocalizedStatus(String s) {
    final l = AppLocalizations.of(context)!;
    switch(s.toUpperCase()){
      case 'REQUESTED': return l.statusRequested;
      case 'PENDING_AGENTS': return l.statusPendingAgents;
      case 'BIDDING_ACTIVE': return l.statusBiddingActive;
      case 'QUOTED': return l.statusQuoted;
      case 'ACCEPTED': return l.statusAccepted;
      case 'BOOKED': return l.statusBooked;
      case 'READY_FOR_PICKUP': return l.readyForPickup;
      case 'IN_TRANSIT': return l.statusInTransit;
      case 'DELIVERED': return l.statusDelivered;
      case 'CANCELLED': return l.statusCancelled;
      default: return s.replaceAll('_', ' ');
    }
  }
  
  Color _getStatusColor(String s) {
    switch (s.toUpperCase()) {
      case 'DELIVERED': return Colors.green;
      case 'IN_TRANSIT': return Colors.blue;
      case 'PICKED_UP': return Colors.cyan;
      case 'CANCELLED': return Colors.red;
      default: return Colors.orange;
    }
  }
  
  bool get _isAssignedAgent => context.read<AuthBloc>().state.user?.id == _shipment.agentId;
  bool get _isAgentRole => context.read<AuthBloc>().state.user?.role == 'AGENT';
}
