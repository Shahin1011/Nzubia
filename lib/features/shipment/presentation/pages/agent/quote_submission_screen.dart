import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/shipment_detail/cargo_item_detail_screen.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/quote_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';

class QuoteSubmissionScreen extends StatefulWidget {
  final ShipmentEntity shipment;

  const QuoteSubmissionScreen({super.key, required this.shipment});

  @override
  State<QuoteSubmissionScreen> createState() => _QuoteSubmissionScreenState();
}

class _QuoteSubmissionScreenState extends State<QuoteSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _baseChargeController = TextEditingController();
  final _customsController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _insuranceNameController = TextEditingController();
  final _notesController = TextEditingController();

  String _currency = 'USD';
  String _shippingMethod = 'AIR';
  String _payoutMethod = 'STRIPE';
  String _insuranceType = 'NZUBIA';
  DateTime? _eta;
  bool _isLoading = false;
  bool _termsAccepted = false;

  // Platform markup info
  bool _markupEnabled = false;
  String _markupType = 'PERCENTAGE';
  double _markupValue = 0;
  bool _loadingMarkup = true;

  // Insurance info from platform
  double _nzubiaInsurancePercentage = 0;

  @override
  void initState() {
    super.initState();
    _fetchPlatformSettings();
  }

  Future<void> _fetchPlatformSettings() async {
    try {
      final dioClient = sl<DioClient>();
      
      // Fetch Markup and Insurance settings in parallel
      final results = await Future.wait([
        dioClient.dio.get('/platform-settings/markup-info'),
        dioClient.dio.get('/platform-settings/insurance-info'),
      ]);

      if (mounted) {
        setState(() {
          // Markup
          final markupData = results[0].data;
          _markupEnabled = markupData['enabled'] == true;
          _markupType = markupData['type'] ?? 'PERCENTAGE';
          _markupValue = (markupData['value'] ?? 0).toDouble();
          
          // Insurance
          final insuranceData = results[1].data;
          _nzubiaInsurancePercentage = (insuranceData['percentage'] ?? 0).toDouble();
          
          // Pre-fill if NZUBIA is selected
          if (_insuranceType == 'NZUBIA') {
            final fee = (widget.shipment.totalItemValue * _nzubiaInsurancePercentage) / 100;
            _insuranceController.text = fee.toStringAsFixed(2);
            _insuranceNameController.text = 'Nzubia Platform Insurance';
          }
          
          _loadingMarkup = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMarkup = false);
    }
  }

  double get _quoteAmount {
    final base = double.tryParse(_baseChargeController.text) ?? 0;
    final customs = double.tryParse(_customsController.text) ?? 0;
    return base + customs;
  }

  double get _platformCut {
    if (!_markupEnabled || _quoteAmount <= 0) return 0;
    if (_markupType == 'FIXED') return _markupValue;
    return (_quoteAmount * _markupValue) / 100;
  }

  double get _agentEarnings {
    if (_insuranceType == 'PRIVATE') {
      return _quoteAmount + _insuranceFee;
    }
    return _quoteAmount;
  }

  double get _insuranceFee => double.tryParse(_insuranceController.text) ?? 0;

  double get _totalForCustomer => _quoteAmount + _platformCut + _insuranceFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quote for ${widget.shipment.id.substring(0, 8)}...'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route: ${widget.shipment.originCity} -> ${widget.shipment.destinationCountry}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.shipment.totalItemValue > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer Declared Item Value', style: TextStyle(fontSize: 12, color: Colors.blue)),
                            Text(
                              '\$${widget.shipment.totalItemValue.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Shipping Method
              DropdownButtonFormField<String>(
                initialValue: _shippingMethod,
                decoration: const InputDecoration(labelText: 'Shipping Method', border: OutlineInputBorder()),
                items: ['AIR', 'SEA', 'LAND']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _shippingMethod = v!),
              ),
              const SizedBox(height: 16),

              // Currency
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                items: ['USD', 'EUR', 'GBP']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),
              const SizedBox(height: 16),

              // Payout Method
              DropdownButtonFormField<String>(
                initialValue: _payoutMethod,
                decoration: const InputDecoration(
                  labelText: 'Payout Method', 
                  border: OutlineInputBorder(),
                  helperText: 'How you want to receive funds for this shipment',
                ),
                items: const [
                  DropdownMenuItem(value: 'STRIPE', child: Text('Stripe (Automatic)')),
                  DropdownMenuItem(value: 'ZELLE', child: Text('Zelle (Manual)')),
                ],
                onChanged: (v) => setState(() => _payoutMethod = v!),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _eta = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Estimated Delivery Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _eta == null
                        ? 'Select Delivery Date'
                        : _eta.toString().split(' ')[0],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Breakdown
              const Text(
                'Cost Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _baseChargeController,
                decoration: const InputDecoration(labelText: 'Base Shipping Charge', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customsController,
                decoration: const InputDecoration(labelText: 'Customs Fee (Optional)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 24),
              // Insurance Choice Indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.shipment.insuranceRequested
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.shipment.insuranceRequested
                        ? Colors.green.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.shipment.insuranceRequested
                          ? Icons.verified_user
                          : Icons.info_outline,
                      color: widget.shipment.insuranceRequested
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shipment.insuranceRequested
                                ? 'Customer Requested Insurance'
                                : 'Insurance Not Requested by Customer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.shipment.insuranceRequested
                                  ? Colors.green.shade800
                                  : Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            widget.shipment.insuranceRequested
                                ? 'Please provide your insurance fee if applicable.'
                                : 'Insurance options are disabled for this shipment.',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.shipment.insuranceRequested
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.shipment.insuranceRequested) ...[
                // Insurance Type Toggle
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _insuranceType,
                  decoration: const InputDecoration(
                    labelText: 'Insurance Provider',
                    helperText: 'Select who provides insurance coverage',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'PRIVATE',
                      child: Text('Agent\'s Own Insurance'),
                    ),
                    if (_nzubiaInsurancePercentage > 0 || _insuranceType == 'NZUBIA')
                      const DropdownMenuItem(
                        value: 'NZUBIA',
                        child: Text('Nzubia Insurance'),
                      ),

                  ],
                  onChanged: (v) {
                    setState(() {
                      _insuranceType = v!;
                      if (_insuranceType == 'NZUBIA') {
                        final fee = (widget.shipment.totalItemValue * _nzubiaInsurancePercentage) / 100;
                        _insuranceController.text = fee.toStringAsFixed(2);
                        _insuranceNameController.text = 'Nzubia Platform Insurance';
                      } else if (_insuranceType == 'NONE') {
                        _insuranceController.text = '0';
                        _insuranceNameController.text = '';
                      } else {
                        // For PRIVATE, clear or let user fill
                        _insuranceController.text = '';
                        _insuranceNameController.text = '';
                      }
                    });
                  },
                ),
                if (_insuranceType == 'PRIVATE') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _insuranceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Insurance Name',
                      hintText: 'e.g. Lloyds Cargo Cover',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _insuranceController,
                  decoration: InputDecoration(
                    labelText: 'Insurance Fee',
                    helperText: _insuranceType == 'NZUBIA'
                        ? 'Nzubia\'s insurance cost ($_nzubiaInsurancePercentage%)'
                        : 'Your insurance cost',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: _insuranceType == 'NZUBIA',
                  onChanged: (_) => setState(() {}),
                ),
              ],

              const SizedBox(height: 24),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes / Inclusions',
                  hintText: 'e.g. Customs fees included, fragile handling...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // Platform Cut Breakdown Card
              if (_quoteAmount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: _loadingMarkup
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earnings Breakdown',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _buildRow(
                              'Your Base Quote',
                              '$_currency ${_quoteAmount.toStringAsFixed(2)}',
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            if (_markupEnabled) ...[
                              _buildRow(
                                'Platform Fee (${_markupType == 'PERCENTAGE' ? '${_markupValue.toStringAsFixed(0)}%' : 'Fixed'})',
                                '+ $_currency ${_platformCut.toStringAsFixed(2)}',
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ],
                            if (_insuranceFee > 0) ...[
                              _buildRow(
                                'Insurance Fee (${_insuranceType == 'NZUBIA' ? 'Nzubia' : 'Private'})',
                                '+ $_currency ${_insuranceFee.toStringAsFixed(2)}',
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ],
                            const Divider(height: 24),
                            _buildRow(
                              'Total Customer Pays',
                              '$_currency ${_totalForCustomer.toStringAsFixed(2)}',
                              bold: true,
                              color: const Color(0xFF22878D),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You will receive \$${_agentEarnings.toStringAsFixed(2)} upon successful delivery (Base + Private Insurance if any).',
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                ),

              const SizedBox(height: 24),

              // Cargo Manifest Section
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Cargo Manifest',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...widget.shipment.cargoItems
                  .map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CargoItemDetailScreen(
                                item: item,
                                shipment: widget.shipment,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              if (item.imageUrls.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    item.imageUrls.first,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${item.category} • ${item.quantity} units',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  ,

              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                    activeColor: Colors.blue,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        AppLocalizations.of(context)!.quoteLegalConsent,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_termsAccepted) ? null : _submitQuote,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Quote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitQuote() async {
    if (_formKey.currentState!.validate() && _eta != null) {
      setState(() => _isLoading = true);
      try {
        await sl<QuoteRepository>().createQuote(
          shipmentId: widget.shipment.id,
          amount: _quoteAmount,
          notes: _notesController.text,
          method: _shippingMethod,
          deliveryDate: _eta!,
          payoutMethod: _payoutMethod,
          insuranceType: _insuranceType,
          insuranceName: _insuranceNameController.text,
          insuranceFee: _insuranceFee,
          legalGoodsTermsAccepted: _termsAccepted,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quote Submitted Successfully!')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_eta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select ETA')),
      );
    }
  }

  Widget _buildRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.grey.shade800,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
