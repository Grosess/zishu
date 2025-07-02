import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'premium_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();
  
  final PremiumService _premiumService = PremiumService();
  
  // Test Ad Unit IDs - Replace with your actual ad unit IDs in production
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test banner
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test interstitial
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  BannerAd? _practiceBannerAd;
  BannerAd? _setsBannerAd;
  InterstitialAd? _interstitialAd;
  
  bool _isPracticeBannerAdReady = false;
  bool _isSetsBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  
  bool get isPracticeBannerAdReady => _isPracticeBannerAdReady && !_premiumService.isPremium;
  bool get isSetsBannerAdReady => _isSetsBannerAdReady && !_premiumService.isPremium;
  
  Future<void> initialize() async {
    if (_premiumService.isPremium) {
      return; // No ads for premium users
    }
    
    await MobileAds.instance.initialize();
    
    // Load ads
    _loadPracticeBannerAd();
    _loadSetsBannerAd();
    _loadInterstitialAd();
  }
  
  void _loadPracticeBannerAd() {
    if (_premiumService.isPremium) return;
    
    _practiceBannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isPracticeBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          _isPracticeBannerAdReady = false;
          ad.dispose();
          // Retry after delay
          Future.delayed(const Duration(minutes: 1), () {
            if (!_premiumService.isPremium) {
              _loadPracticeBannerAd();
            }
          });
        },
      ),
    );
    
    _practiceBannerAd!.load();
  }
  
  void _loadSetsBannerAd() {
    if (_premiumService.isPremium) return;
    
    _setsBannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isSetsBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          _isSetsBannerAdReady = false;
          ad.dispose();
          // Retry after delay
          Future.delayed(const Duration(minutes: 1), () {
            if (!_premiumService.isPremium) {
              _loadSetsBannerAd();
            }
          });
        },
      ),
    );
    
    _setsBannerAd!.load();
  }
  
  void _loadInterstitialAd() {
    if (_premiumService.isPremium) return;
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialAdReady = false;
          // Retry after delay
          Future.delayed(const Duration(minutes: 2), () {
            if (!_premiumService.isPremium) {
              _loadInterstitialAd();
            }
          });
        },
      ),
    );
  }
  
  Widget? getPracticeBannerAdWidget() {
    if (!isPracticeBannerAdReady || _practiceBannerAd == null) {
      return null;
    }
    
    return Container(
      alignment: Alignment.center,
      width: _practiceBannerAd!.size.width.toDouble(),
      height: _practiceBannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _practiceBannerAd!),
    );
  }
  
  Widget? getSetsBannerAdWidget() {
    if (!isSetsBannerAdReady || _setsBannerAd == null) {
      return null;
    }
    
    return Container(
      alignment: Alignment.center,
      width: _setsBannerAd!.size.width.toDouble(),
      height: _setsBannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _setsBannerAd!),
    );
  }
  
  Future<void> showInterstitialAd() async {
    if (!_isInterstitialAdReady || _interstitialAd == null || _premiumService.isPremium) {
      return;
    }
    
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _loadInterstitialAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _loadInterstitialAd(); // Load next ad
      },
    );
    
    await _interstitialAd!.show();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
  
  void dispose() {
    _practiceBannerAd?.dispose();
    _setsBannerAd?.dispose();
    _interstitialAd?.dispose();
  }
  
  // Show interstitial ad after every N characters practiced
  static int _charactersPracticed = 0;
  static const int _interstitialFrequency = 10;
  
  void onCharacterPracticed() {
    if (_premiumService.isPremium) return;
    
    _charactersPracticed++;
    if (_charactersPracticed >= _interstitialFrequency) {
      _charactersPracticed = 0;
      showInterstitialAd();
    }
  }
}