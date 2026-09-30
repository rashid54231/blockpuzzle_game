import 'dart:async';
import 'package:flutter/foundation.dart';

abstract class IapService {
  Future<void> init();
  Future<bool> buyProduct(String productId);
  Future<bool> restorePurchases();
  Stream<String> get onPurchaseSuccess;
  bool get isAvailable;
  void dispose();
}

class MockIapService implements IapService {
  final _purchaseController = StreamController<String>.broadcast();

  @override
  bool get isAvailable => true;

  @override
  Stream<String> get onPurchaseSuccess => _purchaseController.stream;

  @override
  Future<void> init() async {
    debugPrint('[MockIapService] Initialized');
  }

  @override
  Future<bool> buyProduct(String productId) async {
    debugPrint('[MockIapService] Purchased $productId (mock)');
    _purchaseController.add(productId);
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    debugPrint('[MockIapService] Restored purchases (mock)');
    return true;
  }

  @override
  void dispose() {
    _purchaseController.close();
  }
}
