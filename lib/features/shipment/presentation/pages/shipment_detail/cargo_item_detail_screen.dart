import 'package:flutter/material.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/cargo_item_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/shipment_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'dart:io';

import 'package:customer_nzubia_global/l10n/app_localizations.dart';

class CargoItemDetailScreen extends StatefulWidget {
  final CargoItemEntity item;
  final ShipmentEntity shipment;

  const CargoItemDetailScreen({super.key, required this.item, required this.shipment});

  @override
  State<CargoItemDetailScreen> createState() => _CargoItemDetailScreenState();
}

class _CargoItemDetailScreenState extends State<CargoItemDetailScreen> {
  final TextEditingController _requestController = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    // Only agents can request info
    final isAgent = context.read<AuthBloc>().state.user?.role == 'AGENT';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.itemDetails)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.item.imageUrls.isNotEmpty)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black12,
                ),
                child: PageView.builder(
                  itemCount: widget.item.imageUrls.length,
                  itemBuilder: (context, index) {
                    final path = widget.item.imageUrls[index];
                    if (path.startsWith('http')) {
                      return InteractiveViewer(
                        clipBehavior: Clip.none,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.network(
                          path, 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                                  SizedBox(height: 8),
                                  Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      );
                    }
                    return Image.file(File(path), fit: BoxFit.contain);
                  },
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
              ),
            
            const SizedBox(height: 24),
            Text(widget.item.description, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Chip(label: Text(widget.item.category)),
            
            const SizedBox(height: 24),
            _buildDetailRow(l10n.weight, '${widget.item.weight.toStringAsFixed(2)} ${l10n.lbsLabel} / ${(widget.item.weight * 0.453592).toStringAsFixed(1)} ${l10n.kgLabel}'),
            _buildDetailRow(l10n.quantity, '${widget.item.quantity}'),
            _buildDetailRow(
              l10n.dimensions, 
              (widget.item.length > 0 || widget.item.width > 0 || widget.item.height > 0)
                  ? '${widget.item.length} x ${widget.item.width} x ${widget.item.height} ${widget.item.dimensionUnit}'
                  : 'Not specified',
            ),
            const SizedBox(height: 16),
             Row(
                children: [
                  if (widget.item.isFragile)
                    Padding(padding: const EdgeInsets.only(right: 8), child: Chip(label: Text(l10n.fragile), backgroundColor: Colors.orangeAccent)),
                  if (widget.item.isPerishable)
                    Chip(label: Text(l10n.perishable), backgroundColor: Colors.lightBlueAccent),
                ],
             ),

            const SizedBox(height: 32),
            if (isAgent) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(l10n.requestMoreInfo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              TextField(
                controller: _requestController,
                decoration: InputDecoration(
                  labelText: l10n.whatInfoNeeded,
                  hintText: l10n.infoRequestHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendRequest,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: _isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Text(l10n.sendRequest, style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _sendRequest() async {
    final l10n = AppLocalizations.of(context)!;
    if (_requestController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterMessage)));
      return;
    }

    setState(() => _isSending = true);
    try {
      await sl<ShipmentRepository>().requestInfo(
        widget.shipment.id, 
        'Re: ${widget.item.description} - ${_requestController.text}'
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestSentToCustomer)));
        _requestController.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red[700],
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
