import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/payment/presentation/bloc/history/payment_history_bloc.dart';
import 'package:customer_nzubia_global/features/payment/presentation/bloc/history/payment_history_event.dart';
import 'package:customer_nzubia_global/features/payment/presentation/bloc/history/payment_history_state.dart';
import 'package:customer_nzubia_global/features/payment/domain/entities/payment_entity.dart';
import 'package:customer_nzubia_global/core/widgets/offline_error_widget.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentHistoryBloc(repository: sl())..add(LoadPaymentHistory()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment History'),
        ),
        body: BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
          builder: (context, state) {
            if (state.status == PaymentHistoryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == PaymentHistoryStatus.failure) {
              return OfflineErrorWidget(
                errorMessage: state.errorMessage ?? 'An error occurred',
                onRetry: () {
                  context.read<PaymentHistoryBloc>().add(LoadPaymentHistory());
                },
              );
            }
            if (state.payments.isEmpty) {
              return const Center(child: Text('No payment history found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.payments.length,
              itemBuilder: (context, index) {
                final payment = state.payments[index];
                return _PaymentCard(payment: payment);
              },
            );
          },
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentEntity payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: payment.currency);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final isSuccess = payment.status == 'SUCCEEDED';
    final color = isSuccess ? Colors.greenAccent : (payment.status == 'FAILED' ? Colors.redAccent : Colors.orangeAccent);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: () {
          if (payment.shipment != null) {
            context.push('/shipment-details', extra: payment.shipment);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(payment.amount),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      payment.status,
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Shipment: ${payment.shipment?.id.substring(0, 8).toUpperCase() ?? "N/A"}', // Fallback if no shipment logic needs improvement
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(payment.createdAt),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
