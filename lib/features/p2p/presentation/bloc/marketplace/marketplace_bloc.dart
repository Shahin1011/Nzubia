import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_route_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';

part 'marketplace_event.dart';
part 'marketplace_state.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final P2pRouteRepository _repository;
  final P2pCourierRepository _courierRepository;
  MarketplaceRouteFeedRequested _lastFilter =
      const MarketplaceRouteFeedRequested();

  MarketplaceBloc({
    required P2pRouteRepository repository,
    required P2pCourierRepository courierRepository,
  })  : _repository = repository,
        _courierRepository = courierRepository,
        super(const MarketplaceState()) {
    on<MarketplaceRouteFeedRequested>(_onFeedRequested);
    on<MarketplaceRefreshed>(_onRefreshed);
  }

  Future<void> _onFeedRequested(
    MarketplaceRouteFeedRequested event,
    Emitter<MarketplaceState> emit,
  ) async {
    _lastFilter = event;
    emit(state.copyWith(status: MarketplaceStatus.loading));
    try {
      // Fetch feed and courier status in parallel; courier check is non-fatal.
      final results = await Future.wait([
        _repository.getRouteFeed(
          destinationCountry: event.destinationCountry,
          destinationCity: event.destinationCity,
        ),
        _courierRepository.getMyProfile().then<bool?>((p) => p != null).catchError((_) => null),
      ]);

      final feed = results[0] as List<P2pRouteFeedItem>;
      final isCourier = results[1] as bool?;
      final routes = feed.map((item) => item.route).toList();

      emit(state.copyWith(
        status: MarketplaceStatus.success,
        routes: routes,
        feed: feed,
        isCourier: isCourier ?? false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MarketplaceStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshed(
    MarketplaceRefreshed event,
    Emitter<MarketplaceState> emit,
  ) async {
    add(_lastFilter);
  }
}
