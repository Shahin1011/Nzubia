import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/core/services/payment_service.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final PaymentService _paymentService;
  late double _amount;
  late String _currency;
  late String _quoteId;

  CheckoutBloc({required PaymentService paymentService})
      : _paymentService = paymentService,
        super(const CheckoutState()) {
    on<CheckoutInitialized>(_onInitialized);
    on<CheckoutPaymentRequested>(_onPaymentRequested);
    on<CheckoutPaymentVerified>((event, emit) {
      emit(state.copyWith(status: CheckoutStatus.success));
    });
  }

  void _onInitialized(CheckoutInitialized event, Emitter<CheckoutState> emit) {
    _amount = event.amount;
    _currency = event.currency;
    _quoteId = event.quoteId;
  }

  Future<void> _onPaymentRequested(CheckoutPaymentRequested event, Emitter<CheckoutState> emit) async {
    emit(state.copyWith(status: CheckoutStatus.loading));
    try {
      await _paymentService.initPaymentSheet(amount: _amount.toString(), currency: _currency, quoteId: _quoteId);
      await _paymentService.presentPaymentSheet();
      emit(state.copyWith(status: CheckoutStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
