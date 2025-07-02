import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'premium_service.dart';

class ConnectivityService with ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  final PremiumService _premiumService = PremiumService();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  
  bool get isOnline => _isOnline;
  bool get canUseOffline => _premiumService.isPremium;
  bool get isAccessible => _isOnline || canUseOffline;
  
  Future<void> initialize() async {
    // Check initial connectivity
    await checkConnectivity();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
    );
  }
  
  Future<void> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }
  
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
    
    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  // Show offline dialog for free users
  void showOfflineDialog(BuildContext context) {
    if (!_isOnline && !canUseOffline) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Offline Mode'),
          content: const Text(
            'You need an internet connection to use Zishu.\n\n'
            'Upgrade to Premium to practice offline and remove ads!'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to premium screen
                Navigator.pushNamed(context, '/premium');
              },
              child: const Text('Go Premium'),
            ),
          ],
        ),
      );
    }
  }
}