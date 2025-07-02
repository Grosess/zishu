import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class PremiumService with ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  static const String _premiumProductId = 'zishu_premium';
  static const String _premiumPrefKey = 'is_premium_user';
  
  bool _isPremium = false;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _loading = true;
  String? _queryProductError;
  
  bool get isPremium => _isPremium;
  bool get isAvailable => _isAvailable;
  bool get loading => _loading;
  String? get queryProductError => _queryProductError;
  List<ProductDetails> get products => _products;
  
  Future<void> initialize() async {
    // Check stored premium status first
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumPrefKey) ?? false;
    notifyListeners();
    
    // Check if IAP is available
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      _loading = false;
      notifyListeners();
      return;
    }
    
    // Set up purchase updates listener
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        print('Purchase stream error: $error');
      },
    );
    
    // Load products
    await loadProducts();
  }
  
  Future<void> loadProducts() async {
    _loading = true;
    notifyListeners();
    
    try {
      final Set<String> kIds = <String>{_premiumProductId};
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(kIds);
          
      if (response.notFoundIDs.isNotEmpty) {
        _queryProductError = 'Products not found: ${response.notFoundIDs}';
        print(_queryProductError);
      }
      
      _products = response.productDetails;
      _loading = false;
      notifyListeners();
      
      // Restore purchases to check if user already bought premium
      await restorePurchases();
    } catch (e) {
      _queryProductError = e.toString();
      _loading = false;
      notifyListeners();
    }
  }
  
  Future<void> buyPremium() async {
    if (_products.isEmpty) {
      throw Exception('Premium product not available');
    }
    
    final ProductDetails productDetails = _products.first;
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    
    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Error purchasing premium: $e');
      rethrow;
    }
  }
  
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }
  
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        continue;
      }
      
      if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        print('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase
        final bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          await _deliverProduct(purchaseDetails);
        }
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In production, verify the purchase with your server
    // For now, we'll just return true
    return true;
  }
  
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == _premiumProductId) {
      // Save premium status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumPrefKey, true);
      _isPremium = true;
      notifyListeners();
    }
  }
  
  Future<void> setPremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumPrefKey, isPremium);
    _isPremium = isPremium;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
  
  // Helper method to check if feature is available
  bool isFeatureAvailable(String feature) {
    switch (feature) {
      case 'offline_mode':
      case 'no_ads':
      case 'radical_analysis':
        return _isPremium;
      default:
        return true;
    }
  }
  
  // Get price string for display
  String getPriceString() {
    if (_products.isEmpty) return 'Premium';
    return _products.first.price;
  }
}