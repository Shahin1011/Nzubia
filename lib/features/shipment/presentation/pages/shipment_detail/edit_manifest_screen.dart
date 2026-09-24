import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/cargo_item_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/shipment_repository.dart';

import 'package:customer_nzubia_global/l10n/app_localizations.dart';

class EditManifestScreen extends StatefulWidget {
  final ShipmentEntity shipment;

  const EditManifestScreen({super.key, required this.shipment});

  @override
  State<EditManifestScreen> createState() => _EditManifestScreenState();
}

class _EditManifestScreenState extends State<EditManifestScreen> {
  late List<CargoItemEntity> _items;
  bool _isSaving = false;

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _qtyController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedCategory = 'GENERAL';
  bool _isFragile = false;
  bool _isPerishable = false;
  List<String> _tempImagePaths = [];

  final List<String> _categories = ['GENERAL', 'ELECTRONICS', 'FURNITURE', 'CLOTHING', 'MACHINERY', 'PERISHABLE', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.shipment.cargoItems);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _weightController.dispose();
    _qtyController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (pickedFiles.isNotEmpty && mounted) {
      setState(() {
        _tempImagePaths.addAll(pickedFiles.map((e) => e.path));
      });
    }
  }

  void _addItem() {
    if (_descriptionController.text.isEmpty) return;

    final item = CargoItemEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: _descriptionController.text,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      length: double.tryParse(_lengthController.text) ?? 0.0,
      width: double.tryParse(_widthController.text) ?? 0.0,
      height: double.tryParse(_heightController.text) ?? 0.0,
      quantity: int.tryParse(_qtyController.text) ?? 1,
      category: _selectedCategory,
      isFragile: _isFragile,
      isPerishable: _isPerishable,
      imageUrls: List.from(_tempImagePaths),
    );

    setState(() {
      _items.add(item);
      _resetForm();
    });
  }

  void _resetForm() {
    _descriptionController.clear();
    _weightController.clear();
    _qtyController.clear();
    _lengthController.clear();
    _widthController.clear();
    _heightController.clear();
    setState(() {
      _selectedCategory = 'GENERAL';
      _isFragile = false;
      _isPerishable = false;
      _tempImagePaths = [];
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveManifest() async {
    setState(() => _isSaving = true);
    try {
      final updatedShipment = await sl<ShipmentRepository>().updateShipment(
        widget.shipment.id,
        items: _items,
      );
      if (mounted) {
        context.pop(updatedShipment);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editManifest),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: CircularProgressIndicator(color: Colors.white)))
          else
            TextButton(
              onPressed: _items.isNotEmpty ? _saveManifest : null, // Prevent saving empty manifest?
              child: Text(l10n.save, style: const TextStyle(color: Colors.white, fontSize: 16)),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // List of Items
            if (_items.isNotEmpty) ...[
              Text(l10n.currentManifest, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    child: ListTile(
                       leading: item.imageUrls.isNotEmpty
                          ? Image.file(File(item.imageUrls.first), width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.inventory_2))
                          : const Icon(Icons.inventory_2),
                       title: Text(item.description),
                       subtitle: Text('${item.category} • ${item.weight.toStringAsFixed(2)} ${l10n.lbsLabel} / ${(item.weight * 0.453592).toStringAsFixed(1)} ${l10n.kgLabel}'),
                       trailing: IconButton(
                         icon: const Icon(Icons.delete, color: Colors.red),
                         onPressed: () => _removeItem(index),
                       ),
                    ),
                  );
                },
              ),
              const Divider(height: 32),
            ],

            Text(l10n.addNewItem, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            // Add Form
            _buildAddForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(labelText: l10n.category, border: const OutlineInputBorder()),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(labelText: l10n.description, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: '${l10n.weight} (${l10n.lbsLabel})', helperText: l10n.weightConversionHelper, border: const OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.quantity, border: const OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dimensions
        Text("${l10n.dimensions} (${l10n.cmLabel})", style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextField(controller: _lengthController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.lLabel, border: const OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _widthController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.wLabel, border: const OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _heightController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.hLabel, border: const OutlineInputBorder()))),
          ],
        ),
        const SizedBox(height: 12),

        // Switches
        SwitchListTile(
          title: Text(l10n.isFragileQuestion),
          value: _isFragile,
          onChanged: (val) => setState(() => _isFragile = val),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: Text(l10n.isPerishableQuestion),
          value: _isPerishable,
          onChanged: (val) => setState(() => _isPerishable = val),
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 12),
        // Images
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _tempImagePaths.isNotEmpty
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: _tempImagePaths.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Image.file(File(_tempImagePaths[index]), width: 80, fit: BoxFit.cover),
                      );
                    },
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.grey),
                      Text(l10n.addPhotos),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: Text(l10n.addItemToManifest),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.clickSaveToApply,
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
