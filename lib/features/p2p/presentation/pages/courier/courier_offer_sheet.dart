import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_route_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';

class CourierOfferSheet extends StatefulWidget {
  final P2pShipmentRequest shipment;
  final VoidCallback? onSubmitted;

  const CourierOfferSheet({super.key, required this.shipment, this.onSubmitted});

  @override
  State<CourierOfferSheet> createState() => _CourierOfferSheetState();
}

class _CourierOfferSheetState extends State<CourierOfferSheet> {
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<P2pRoute> _publishedRoutes = [];
  String? _selectedRouteId;
  bool _loadingRoutes = true;
  bool _submitting = false;
  String? _routeError;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      final routes =
          await GetIt.instance<P2pRouteRepository>().listMyRoutes();
      if (!mounted) return;
      final published =
          routes.where((r) => r.status == RouteStatus.published).toList();
      setState(() {
        _publishedRoutes = published;
        _selectedRouteId =
            published.isNotEmpty ? published.first.id : null;
        _loadingRoutes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeError = e.toString();
        _loadingRoutes = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a route to proceed')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await GetIt.instance<P2pShipmentRepository>().createOffer(
        widget.shipment.id,
        {
          'offerAmountUsd': double.parse(_amountCtrl.text.trim()),
          'routeId': _selectedRouteId,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer submitted!')),
      );
      widget.onSubmitted?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Submit Offer', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${widget.shipment.itemCategory.label} → ${widget.shipment.destinationCity}, ${widget.shipment.destinationCountry}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(
                    label: 'Weight',
                    value:
                        '${widget.shipment.weightKg.toStringAsFixed(1)} kg',
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _Stat(
                    label: 'Declared value',
                    value:
                        '\$${widget.shipment.declaredValueUsd.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Your offer (USD)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an amount';
                final val = double.tryParse(v.trim());
                if (val == null || val <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_loadingRoutes)
              const Center(child: CircularProgressIndicator())
            else if (_routeError != null)
              Text(
                'Could not load routes: $_routeError',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              )
            else if (_publishedRoutes.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'You have no published routes. Publish a route first to submit offers.',
                  style: TextStyle(fontSize: 13),
                ),
              )
            else ...[
              Text('Route', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedRouteId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _publishedRoutes.map((r) {
                  final date = DateFormat.MMMd().format(r.departureDate);
                  return DropdownMenuItem(
                    value: r.id,
                    child: Text(
                      '${r.destinationCity}, ${r.destinationCountry} — $date',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedRouteId = v),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    (_submitting || _publishedRoutes.isEmpty) ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
