import 'package:equatable/equatable.dart';

abstract class ShipmentListEvent extends Equatable {
  const ShipmentListEvent();

  @override
  List<Object?> get props => [];
}

class LoadShipments extends ShipmentListEvent {
  final String? statusFilter;
  final String? searchQuery;
  final bool isLoadMore;

  const LoadShipments({
    this.statusFilter,
    this.searchQuery,
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [statusFilter, searchQuery, isLoadMore];
}
