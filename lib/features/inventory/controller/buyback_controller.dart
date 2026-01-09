import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a complete Used Phone Buyback record with seller and phone details
class BuybackRecord {
  final String id;
  final String productId; // Links to Product in inventory
  
  // Seller Information
  final String sellerName;
  final String sellerPhone;
  final String sellerCnic;
  final String? cnicFrontPath;
  final String? cnicBackPath;
  
  // Phone Information
  final String brand;
  final String model;
  final String imei;
  final String? imei2; // For dual-SIM phones
  final String? variant;
  final String condition;
  final double purchasePrice;
  final double? sellingPrice; // For listing
  final String? phoneImage1Path;
  final String? phoneImage2Path;
  
  // Listing status
  final bool isListed; // Whether product is listed in inventory/POS
  
  // Timestamps
  final DateTime createdAt;
  final String? notes;
  
  BuybackRecord({
    required this.id,
    required this.productId,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerCnic,
    this.cnicFrontPath,
    this.cnicBackPath,
    required this.brand,
    required this.model,
    required this.imei,
    this.imei2,
    this.variant,
    required this.condition,
    required this.purchasePrice,
    this.sellingPrice,
    this.phoneImage1Path,
    this.phoneImage2Path,
    this.isListed = true, // Auto-list by default
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();
  
  String get fullPhoneName => '$brand $model';
  String get displayImei => imei2 != null ? '$imei / $imei2' : imei;
  
  BuybackRecord copyWith({
    String? sellerName,
    String? sellerPhone,
    String? sellerCnic,
    String? cnicFrontPath,
    String? cnicBackPath,
    String? notes,
    String? phoneImage1Path,
    String? phoneImage2Path,
    bool? isListed,
    double? sellingPrice,
  }) {
    return BuybackRecord(
      id: id,
      productId: productId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerCnic: sellerCnic ?? this.sellerCnic,
      cnicFrontPath: cnicFrontPath ?? this.cnicFrontPath,
      cnicBackPath: cnicBackPath ?? this.cnicBackPath,
      brand: brand,
      model: model,
      imei: imei,
      imei2: imei2,
      variant: variant,
      condition: condition,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      phoneImage1Path: phoneImage1Path ?? this.phoneImage1Path,
      phoneImage2Path: phoneImage2Path ?? this.phoneImage2Path,
      isListed: isListed ?? this.isListed,
      createdAt: createdAt,
      notes: notes ?? this.notes,
    );
  }
}

/// State notifier for managing buyback records
class BuybackNotifier extends StateNotifier<List<BuybackRecord>> {
  BuybackNotifier() : super([]);
  
  void addRecord(BuybackRecord record) {
    state = [...state, record];
  }
  
  void deleteRecord(String id) {
    state = state.where((r) => r.id != id).toList();
  }
  
  /// Toggle listing status
  void toggleListing(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(isListed: !r.isListed) else r
    ];
  }
  
  /// Set listing status explicitly
  void setListed(String id, bool listed) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(isListed: listed) else r
    ];
  }
  
  /// Update selling price
  void updateSellingPrice(String id, double price) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(sellingPrice: price) else r
    ];
  }
  
  BuybackRecord? getByProductId(String productId) {
    try {
      return state.firstWhere((r) => r.productId == productId);
    } catch (_) {
      return null;
    }
  }
  
  BuybackRecord? getById(String id) {
    try {
      return state.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// Get only listed buybacks
  List<BuybackRecord> get listedRecords => state.where((r) => r.isListed).toList();
}

/// Provider for buyback records
final buybackProvider = StateNotifierProvider<BuybackNotifier, List<BuybackRecord>>((ref) {
  return BuybackNotifier();
});

