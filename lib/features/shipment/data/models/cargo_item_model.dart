import 'package:customer_nzubia_global/features/shipment/domain/entities/cargo_item_entity.dart';

class CargoItemModel extends CargoItemEntity {
  const CargoItemModel({
    required super.id,
    required super.description,
    required super.length,
    required super.width,
    required super.height,
    required super.weight,
    required super.category,
    required super.isFragile,
    required super.isPerishable,
    required super.imageUrls,
    super.documentIds,
    required super.quantity,
    super.dimensionUnit,
  });

  factory CargoItemModel.fromJson(Map<String, dynamic> json) {
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // dimensions may be nested under a 'dimensions' key, 'dimensions_cm', 'dimensionsCm', or flat
    
    final dims = (json['dimensions'] is Map) 
        ? json['dimensions'] as Map 
        : (json['dimensions_cm'] is Map 
            ? json['dimensions_cm'] as Map 
            : (json['dimensionsCm'] is Map ? json['dimensionsCm'] as Map : null));
    
    final rawWeight = safeDouble(json['weight'] ?? json['weightKg'] ?? json['weight_kg']);
    final wUnit = (json['weight_unit'] ?? json['weightUnit'])?.toString().toLowerCase();
    final calculatedWeight = wUnit == 'kg' ? (rawWeight * 2.20462) : rawWeight;
    final finalWeight = double.parse(calculatedWeight.toStringAsFixed(2));
    
    return CargoItemModel(
      id: json['id'] ?? '',
      description: json['description'] ?? json['itemDescription'] ?? json['item_description'] ?? '',
      length: safeDouble(dims?['length'] ?? json['length'] ?? json['length_cm'] ?? json['lengthCm']),
      width: safeDouble(dims?['width'] ?? json['width'] ?? json['width_cm'] ?? json['widthCm']),
      height: safeDouble(dims?['height'] ?? json['height'] ?? json['height_cm'] ?? json['heightCm']),
      weight: finalWeight,
      category: json['category'] ?? 'GENERAL',
      isFragile: json['is_fragile'] ?? false,
      isPerishable: json['is_perishable'] ?? false,
      imageUrls: ((json['images'] ?? json['photoUrls'] ?? json['photo_urls']) as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      documentIds: (json['document_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      quantity: json['quantity'] is String ? int.tryParse(json['quantity']) ?? 1 : (json['quantity'] ?? 1),
      dimensionUnit: (dims?['unit'] ?? json['dimension_unit'] ?? 'cm').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'length': length,
      'width': width,
      'height': height,
      'weight': weight,
      'category': category,
      'is_fragile': isFragile,
      'is_perishable': isPerishable,
      'images': imageUrls,
      'document_ids': documentIds,
      'quantity': quantity,
    };
  }
}
