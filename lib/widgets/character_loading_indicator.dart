import 'package:flutter/material.dart';
import '../services/optimized_character_loader.dart';

/// A widget that displays character loading progress
class CharacterLoadingIndicator extends StatefulWidget {
  final Widget child;
  final bool showOverlay;
  
  const CharacterLoadingIndicator({
    super.key,
    required this.child,
    this.showOverlay = true,
  });
  
  @override
  State<CharacterLoadingIndicator> createState() => _CharacterLoadingIndicatorState();
}

class _CharacterLoadingIndicatorState extends State<CharacterLoadingIndicator> {
  final OptimizedCharacterLoader _loader = OptimizedCharacterLoader();
  
  int _loaded = 0;
  int _total = 0;
  String _message = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loader.setProgressCallback(_onProgress);
  }
  
  @override
  void dispose() {
    _loader.setProgressCallback(null);
    super.dispose();
  }
  
  void _onProgress(int loaded, int total, String message) {
    if (mounted) {
      setState(() {
        _loaded = loaded;
        _total = total;
        _message = message;
        _isLoading = loaded < total;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLoading && widget.showOverlay)
          _buildLoadingOverlay(),
      ],
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Loading Characters',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: 250,
                  child: LinearProgressIndicator(
                    value: _total > 0 ? _loaded / _total : null,
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (_total > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '$_loaded / $_total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple inline loading indicator for character sets
class CharacterSetLoadingIndicator extends StatelessWidget {
  final bool isLoading;
  final int loaded;
  final int total;
  final String? message;
  
  const CharacterSetLoadingIndicator({
    super.key,
    required this.isLoading,
    this.loaded = 0,
    this.total = 0,
    this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!isLoading) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              message ?? 'Loading characters...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (total > 0) ...[
            SizedBox(width: 8),
            Text(
              '($loaded/$total)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A mixin to easily add loading state management to StatefulWidgets
mixin CharacterLoadingMixin<T extends StatefulWidget> on State<T> {
  final OptimizedCharacterLoader loader = OptimizedCharacterLoader();
  
  bool _isLoadingCharacters = false;
  double _loadingProgress = 0.0;
  String _loadingMessage = '';
  
  bool get isLoadingCharacters => _isLoadingCharacters;
  double get loadingProgress => _loadingProgress;
  String get loadingMessage => _loadingMessage;
  
  @override
  void initState() {
    super.initState();
    loader.setProgressCallback(_handleLoadingProgress);
  }
  
  @override
  void dispose() {
    loader.setProgressCallback(null);
    super.dispose();
  }
  
  void _handleLoadingProgress(int loaded, int total, String message) {
    if (mounted) {
      setState(() {
        _isLoadingCharacters = loaded < total;
        _loadingProgress = total > 0 ? loaded / total : 0.0;
        _loadingMessage = message;
      });
    }
  }
  
  Future<void> loadCharactersWithProgress(List<String> characters) async {
    setState(() {
      _isLoadingCharacters = true;
    });
    
    try {
      await loader.loadCharacters(characters);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCharacters = false;
        });
      }
    }
  }
}