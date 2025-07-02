import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../main.dart' show DuotoneThemeExtension;

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> with SingleTickerProviderStateMixin {
  final PremiumService _premiumService = PremiumService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _premiumService.addListener(_onPremiumStatusChanged);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _premiumService.removeListener(_onPremiumStatusChanged);
    super.dispose();
  }
  
  void _onPremiumStatusChanged() {
    if (_premiumService.isPremium && mounted) {
      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Zishu Premium! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }
  
  Future<void> _purchasePremium() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _premiumService.buyPremium();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    final isDuotone = duotoneExt?.isDuotoneTheme == true;
    final primaryColor = isDuotone 
        ? duotoneExt!.duotoneColor2! 
        : Theme.of(context).colorScheme.primary;
        
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withValues(alpha: 0.1),
              primaryColor.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Premium icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor,
                            primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Unlock Full Potential',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Master Chinese characters without limits',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Features
                  _buildFeatureCard(
                    icon: Icons.wifi_off,
                    title: 'Offline Mode',
                    description: 'Practice anywhere, anytime without internet',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.block,
                    title: 'No Ads',
                    description: 'Focus on learning without distractions',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.analytics,
                    title: 'Radical Analysis',
                    description: 'Deep insights into character components',
                    color: Colors.purple,
                    isNew: true,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.support,
                    title: 'Priority Support',
                    description: 'Get help when you need it',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 40),
                  
                  // Price
                  if (_premiumService.loading)
                    const CircularProgressIndicator()
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _premiumService.getPriceString(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'One-time purchase • Lifetime access',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Purchase button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _isLoading || !_premiumService.isAvailable 
                            ? null 
                            : _purchasePremium,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Upgrade to Premium',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Restore purchases
                    TextButton(
                      onPressed: _isLoading ? null : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          await _premiumService.restorePurchases();
                          if (mounted && !_premiumService.isPremium) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No previous purchases found'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      child: const Text('Restore Purchases'),
                    ),
                  ],
                  
                  if (!_premiumService.isAvailable)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'In-app purchases not available',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    bool isNew = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}