import 'package:flutter/material.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/quote_repository.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/quote_entity.dart';

class CreateQuoteScreen extends StatefulWidget {
  final ShipmentEntity shipment;
  final QuoteEntity? quote;

  const CreateQuoteScreen({super.key, required this.shipment, this.quote});

  @override
  State<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends State<CreateQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _insuranceNameController = TextEditingController();
  final _insuranceFeeController = TextEditingController();

  String _selectedMethod = 'AIR';
  String _selectedPayoutMethod = 'STRIPE';
  String _selectedInsuranceType = 'NONE';
  DateTime? _deliveryDate;
  bool _isLoading = false;
  bool _legalGoodsTermsAccepted = false;

  // Platform markup info
  bool _markupEnabled = false;
  String _markupType = 'PERCENTAGE';
  double _markupValue = 0;
  bool _loadingMarkup = true;

  // Insurance info from platform
  double _nzubiaInsurancePercentage = 0;
  bool _nzubiaInsuranceEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchPlatformSettings();
    
    // Default insurance based on shipment request
    if (widget.shipment.insuranceRequested) {
      _selectedInsuranceType = 'NZUBIA';
    } else {
      _selectedInsuranceType = 'NONE';
    }

    if (widget.quote != null) {
      if (widget.quote!.breakdown != null) {
         _amountController.text = (widget.quote!.breakdown!['base_charge'] ?? widget.quote!.amount).toString();
         _insuranceFeeController.text = (widget.quote!.breakdown!['insurance_fee'] ?? 0).toString();
      } else {
         _amountController.text = widget.quote!.amount.toString();
      }
      _selectedMethod = widget.quote!.shippingMethod ?? 'AIR';
      _selectedPayoutMethod = widget.quote!.payoutMethod ?? 'STRIPE';
      _selectedInsuranceType = widget.quote!.insuranceType ?? _selectedInsuranceType;
      _insuranceNameController.text = widget.quote!.insuranceName ?? '';
      _deliveryDate = widget.quote!.estimatedDeliveryDate;
      _notesController.text = widget.quote!.notes;
    } else {
      if (widget.shipment.deliveryDate != null && widget.shipment.deliveryDate!.isAfter(DateTime.now())) {
         _deliveryDate = widget.shipment.deliveryDate;
      }
    }
  }

  Future<void> _fetchPlatformSettings() async {
    try {
      final dioClient = sl<DioClient>();
      
      final results = await Future.wait([
        dioClient.dio.get('/platform-settings/markup-info'),
        dioClient.dio.get('/platform-settings/insurance-info'),
      ]);

      if (mounted) {
        setState(() {
          final markupData = results[0].data;
          _markupEnabled = markupData['enabled'] == true;
          _markupType = markupData['type'] ?? 'PERCENTAGE';
          _markupValue = (markupData['value'] ?? 0).toDouble();
          
          final insuranceData = results[1].data;
          _nzubiaInsurancePercentage = (insuranceData['percentage'] ?? 0).toDouble();
          _nzubiaInsuranceEnabled = insuranceData['enabled'] == true;
          
          _loadingMarkup = false;

          if (_selectedInsuranceType == 'NZUBIA' && _insuranceFeeController.text.isEmpty) {
             final fee = (widget.shipment.totalItemValue * _nzubiaInsurancePercentage) / 100;
             _insuranceFeeController.text = fee.toStringAsFixed(2);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMarkup = false);
    }
  }

  double get _baseAmount => double.tryParse(_amountController.text) ?? 0;

  double get _platformCut {
    if (!_markupEnabled || _baseAmount <= 0) return 0;
    if (_markupType == 'FIXED') return _markupValue;
    return (_baseAmount * _markupValue) / 100;
  }

  double get _insuranceFee {
    if (_selectedInsuranceType == 'NONE') return 0;
    if (_selectedInsuranceType == 'NZUBIA') {
       return (widget.shipment.totalItemValue * _nzubiaInsurancePercentage) / 100;
    }
    return double.tryParse(_insuranceFeeController.text) ?? 0;
  }

  double get _totalCustomerPays => _baseAmount + _platformCut + _insuranceFee;

  double get _agentEarnings {
    if (_selectedInsuranceType == 'PRIVATE') {
      return _baseAmount + (double.tryParse(_insuranceFeeController.text) ?? 0);
    }
    return _baseAmount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.quote != null ? l10n.editQuote : l10n.createQuote)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text('${l10n.shipment} #${widget.shipment.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                       const SizedBox(height: 8),
                       Text('${widget.shipment.originAddress} \nto \n${widget.shipment.destinationAddress}'),
                       
                       if (widget.shipment.totalItemValue > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory, color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                Text('Declared Value: \$${widget.shipment.totalItemValue.toStringAsFixed(2)}', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                              ],
                            ),
                          ),
                       ],

                       const Divider(height: 24),
                       if (widget.shipment.deliveryDate != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${l10n.estimatedDelivery}: ${DateFormat('MMM d, y HH:mm').format(widget.shipment.deliveryDate!)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),

                       if (widget.shipment.insuranceRequested)
                          Row(
                            children: [
                              Icon(Icons.shield, size: 14, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Text(l10n.insuranceRequested, style: TextStyle(color: Colors.green.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          )
                       else
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(l10n.noInsurance, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Base Shipping Amount',
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                  helperText: 'Enter the amount you wish to earn from shipping',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.pleaseEnterAmount;
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedMethod,
                decoration: InputDecoration(labelText: l10n.shippingMethod, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'AIR', child: Text(l10n.airFreight)),
                  DropdownMenuItem(value: 'SEA', child: Text(l10n.seaFreight)),
                  DropdownMenuItem(value: 'LAND', child: Text(l10n.landTransport)),
                ],
                onChanged: (val) => setState(() => _selectedMethod = val!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedPayoutMethod,
                decoration: const InputDecoration(
                  labelText: 'Payout Method', 
                  border: OutlineInputBorder(),
                  helperText: 'Choose how you want to receive funds for THIS shipment',
                  helperStyle: TextStyle(fontSize: 11),
                ),
                items: [
                  const DropdownMenuItem(value: 'STRIPE', child: Text('Stripe (Automatic)')),
                  const DropdownMenuItem(value: 'ZELLE', child: Text('Zelle (Manual)')),
                ],
                onChanged: (val) => setState(() => _selectedPayoutMethod = val!),
              ),
              const SizedBox(height: 16),

              if (widget.shipment.insuranceRequested) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedInsuranceType,
                  decoration: const InputDecoration(labelText: 'Insurance Provider', border: OutlineInputBorder()),
                  items: [
                    // Always show current selection, or show NZUBIA if enabled
                    if (_nzubiaInsuranceEnabled || _selectedInsuranceType == 'NZUBIA')
                      DropdownMenuItem(value: 'NZUBIA', child: Text(l10n.nzubiaInsurance)),
                    DropdownMenuItem(value: 'PRIVATE', child: Text(l10n.privateInsurance)),

                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedInsuranceType = val!;
                      if (_selectedInsuranceType == 'NZUBIA') {
                         final fee = (widget.shipment.totalItemValue * _nzubiaInsurancePercentage) / 100;
                         _insuranceFeeController.text = fee.toStringAsFixed(2);
                         _insuranceNameController.text = 'Nzubia Platform Insurance';
                      } else if (_selectedInsuranceType == 'NONE') {
                         _insuranceFeeController.text = '0';
                         _insuranceNameController.text = '';
                      } else {
                         _insuranceFeeController.text = '';
                         _insuranceNameController.text = '';
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _insuranceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Insurance Provider Name', 
                    border: OutlineInputBorder(), 
                    hintText: 'e.g. Lloyds'
                  ),
                  readOnly: _selectedInsuranceType == 'NZUBIA',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _insuranceFeeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Insurance Fee', 
                    prefixText: '\$ ', 
                    border: const OutlineInputBorder(),
                    helperText: _selectedInsuranceType == 'NZUBIA' ? 'Calculated at $_nzubiaInsurancePercentage% of declared value' : 'Your private insurance cost'
                  ),
                  readOnly: _selectedInsuranceType == 'NZUBIA',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
              ],

              InkWell(
                onTap: () async {
                   final date = await showDatePicker(
                     context: context,
                     initialDate: _deliveryDate ?? DateTime.now().add(const Duration(days: 7)),
                     firstDate: DateTime.now(),
                     lastDate: DateTime.now().add(const Duration(days: 365)),
                   );
                   if (date != null) {
                     setState(() => _deliveryDate = date);
                   }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.estDeliveryDate,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _deliveryDate != null ? DateFormat('MMM d, y').format(_deliveryDate!) : l10n.selectDate,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.notesInclusions,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              
              if (_baseAmount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: _loadingMarkup
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Earnings Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                            const SizedBox(height: 12),
                            _buildSummaryRow('Your Base Quote', '\$${_baseAmount.toStringAsFixed(2)}', color: Theme.of(context).textTheme.bodyMedium?.color),
                            if (_markupEnabled)
                              _buildSummaryRow(
                                'Platform Fee (${_markupType == 'PERCENTAGE' ? '${_markupValue.toStringAsFixed(0)}%' : 'Fixed'})',
                                '+ \$${_platformCut.toStringAsFixed(2)}',
                                color: Theme.of(context).textTheme.bodySmall?.color
                              ),
                            if (_insuranceFee > 0)
                              _buildSummaryRow(
                                'Insurance Fee (${_selectedInsuranceType == 'NZUBIA' ? 'Nzubia' : 'Private'})',
                                '+ \$${_insuranceFee.toStringAsFixed(2)}',
                                color: Theme.of(context).textTheme.bodySmall?.color
                              ),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              'Total Customer Pays', 
                              '\$${_totalCustomerPays.toStringAsFixed(2)}',
                              isTotal: true
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You will receive \$${_agentEarnings.toStringAsFixed(2)} upon successful delivery (Base + Private Insurance if any).',
                              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                ),
              ],

              const SizedBox(height: 24),
              CheckboxListTile(
                value: _legalGoodsTermsAccepted,
                onChanged: (val) => setState(() => _legalGoodsTermsAccepted = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'I confirm that all cargo tendered complies with applicable international trade laws and does not include contraband, narcotics, unauthorized weapons, counterfeit goods, or restricted wildlife products.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitQuote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : Text(widget.quote != null ? l10n.updateQuote : l10n.submitQuote, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: color)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 13, fontWeight: FontWeight.bold, color: isTotal ? AppTheme.primaryColor : color)),
        ],
      ),
    );
  }

  Future<void> _submitQuote() async {
    final l10n = AppLocalizations.of(context)!;
    if (_deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select delivery date')));
      return;
    }
    if (!_legalGoodsTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must confirm legal goods compliance before submitting.')));
      return;
    }

     if (_formKey.currentState!.validate()) {
       setState(() => _isLoading = true);
       try {
         if (widget.quote != null) {
             await sl<QuoteRepository>().updateQuote(
               quoteId: widget.quote!.id,
               amount: _baseAmount,
               notes: _notesController.text,
               method: _selectedMethod,
               deliveryDate: _deliveryDate!,
               payoutMethod: _selectedPayoutMethod,
               insuranceType: _selectedInsuranceType,
               insuranceName: _insuranceNameController.text,
               insuranceFee: _insuranceFee,
             );
         } else {
             await sl<QuoteRepository>().createQuote(
               shipmentId: widget.shipment.id,
               amount: _baseAmount,
               notes: _notesController.text,
               method: _selectedMethod,
               deliveryDate: _deliveryDate!,
               payoutMethod: _selectedPayoutMethod,
               insuranceType: _selectedInsuranceType,
               insuranceName: _insuranceNameController.text,
               insuranceFee: _insuranceFee,
               legalGoodsTermsAccepted: _legalGoodsTermsAccepted,
             );
         }

         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(widget.quote != null ? l10n.quoteUpdatedSuccessfully : l10n.quoteSubmittedSuccessfully)),
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
    }
  }
}
