import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_event.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_state.dart';
import 'package:intl/intl.dart';

class AgentShipmentListScreen extends StatelessWidget {
  final String filterStatus;
  final String title;

  const AgentShipmentListScreen({
    super.key,
    required this.filterStatus,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ShipmentListBloc>()..add(LoadShipments(statusFilter: filterStatus)),
      child: BlocBuilder<ShipmentListBloc, ShipmentListState>(
        builder: (context, state) {
           String displayTitle = title;
           if (state.totalCount > 0) {
             displayTitle = '$title (${state.totalCount})';
           }
           return _ShipmentListView(title: displayTitle, filterStatus: filterStatus);
        },
      ),
    );
  }
}

class _ShipmentListView extends StatefulWidget {
  final String title;
  final String filterStatus;

  const _ShipmentListView({required this.title, required this.filterStatus});

  @override
  State<_ShipmentListView> createState() => _ShipmentListViewState();
}

class _ShipmentListViewState extends State<_ShipmentListView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ShipmentListBloc>().add(LoadShipments(
        statusFilter: widget.filterStatus,
        searchQuery: _searchController.text,
        isLoadMore: true,
      ));
    }
  }

  void _onSearchChanged(String value) {
    // Debounce can be added here
    context.read<ShipmentListBloc>().add(LoadShipments(
      statusFilter: widget.filterStatus,
      searchQuery: value,
    ));
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ShipmentListBloc>().add(LoadShipments(
              statusFilter: widget.filterStatus,
              searchQuery: _searchController.text,
            )),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search shipments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              onSubmitted: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: BlocBuilder<ShipmentListBloc, ShipmentListState>(
        builder: (context, state) {
          if (state.status == ShipmentListStatus.loading && state.shipments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.shipments.isEmpty && state.status != ShipmentListStatus.loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.noShipmentsFound),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ShipmentListBloc>().add(LoadShipments(statusFilter: widget.filterStatus)),
                    child: Text(AppLocalizations.of(context)!.refresh),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ShipmentListBloc>().add(LoadShipments(statusFilter: widget.filterStatus));
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              controller: _scrollController,
              itemCount: state.hasReachedMax ? state.shipments.length : state.shipments.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.shipments.length) {
                   return const Center(child: Padding(
                     padding: EdgeInsets.all(8.0),
                     child: CircularProgressIndicator(),
                   ));
                }

                final shipment = state.shipments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('${shipment.originAddress} -> ${shipment.destinationAddress}'),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text('Service: ${shipment.serviceLevel}'),
                            Text('Date: ${DateFormat('MMM d, y').format(DateTime.now())}'),
                        ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                         if (widget.filterStatus.contains('PENDING_AGENTS') || 
                             widget.filterStatus.contains('BIDDING_ACTIVE') || 
                             widget.filterStatus == 'REQUESTED') {
                             await context.push('/agent/quote/create', extra: shipment);
                         } else {
                             await context.push('/shipment-details', extra: shipment);
                         }
                         if (context.mounted) {
                             // Do not auto-refresh on back, logic can be improved
                         }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
