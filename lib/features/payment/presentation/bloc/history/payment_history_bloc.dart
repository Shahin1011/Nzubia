import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/payment/domain/repositories/payment_repository.dart';
import 'payment_history_event.dart';
import 'payment_history_state.dart';

class PaymentHistoryBloc extends Bloc<PaymentHistoryEvent, PaymentHistoryState> {
  final PaymentRepository repository;

  PaymentHistoryBloc({required this.repository}) : super(const PaymentHistoryState()) {
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
  }

  Future<void> _onLoadPaymentHistory(LoadPaymentHistory event, Emitter<PaymentHistoryState> emit) async {
    emit(const PaymentHistoryState(status: PaymentHistoryStatus.loading));
    try {
      final payments = await repository.getPayments();
      if (kDebugMode) debugPrint("PAYMENTS $payments");
      emit(PaymentHistoryState(status: PaymentHistoryStatus.success, payments: payments));
    } catch (e) {
      emit(PaymentHistoryState(status: PaymentHistoryStatus.failure, errorMessage: e.toString()));
    }
  }
}
