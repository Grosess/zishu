import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/character_set_manager.dart';
import '../main.dart' show DuotoneThemeExtension;

class SetEditPage extends StatefulWidget {
  final CharacterSet set;
  final VoidCallback? onSetUpdated;

  const SetEditPage({
    super.key,
    required this.set,
    this.onSetUpdated,
  });

  @override
  State<SetEditPage> createState() => _SetEditPageState();
}

class _SetEditPageState extends State<SetEditPage> with SingleTickerProviderStateMixin {
  final CharacterSetManager _setManager = CharacterSetManager();
  
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _addItemController;
  
  late List<String> _items;
  final Set<int> _selectedIndices = {};
  
  bool _isSelectionMode = true; // Default to selection mode
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _isEditingName = false;
  bool _useListView = false; // Toggle between grid and list view
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0); // Start with Add tab (index 0 since Add is now first)
    _nameController = TextEditingController(text: widget.set.name);
    _addItemController = TextEditingController();
    _items = List<String>.from(widget.set.characters);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addItemController.dispose();
    super.dispose();
  }
  
  void _addItem() {
    final text = _addItemController.text.trim();
    if (text.isEmpty) return;
    
    // Split by commas, spaces, or newlines for bulk add
    final newItems = text.split(RegExp(r'[,\s\n]+'))
        .where((item) => item.trim().isNotEmpty)
        .map((item) => item.trim())
        .where((item) => !_items.contains(item))
        .toList();
    
    if (newItems.isNotEmpty) {
      setState(() {
        _items.addAll(newItems);
        _hasUnsavedChanges = true;
      });
      
      _addItemController.clear();
      
      final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
      final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${newItems.length} item${newItems.length > 1 ? 's' : ''}'),
          duration: const Duration(seconds: 1),
          backgroundColor: isDuotone 
              ? duotoneExt?.duotoneColor2
              : null,
        ),
      );
    }
  }
  
  void _removeSelectedItems() {
    if (_selectedIndices.isEmpty) return;
    
    final count = _selectedIndices.length;
    setState(() {
      final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final index in sortedIndices) {
        if (index < _items.length) {
          _items.removeAt(index);
        }
      }
      
      _selectedIndices.clear();
      _isSelectionMode = false;
      _hasUnsavedChanges = true;
    });
    
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed $count item${count > 1 ? 's' : ''}'),
        duration: const Duration(seconds: 1),
        backgroundColor: isDuotone 
            ? duotoneExt?.duotoneColor2
            : null,
      ),
    );
  }
  
  Future<void> _saveChanges() async {
    if (_items.isEmpty) {
      final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
      final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot save an empty set'),
          backgroundColor: isDuotone 
              ? duotoneExt?.duotoneColor2
              : Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Auto-detect if this is a word set
      final isWordSet = _items.any((item) => item.length > 1);
      
      // Create updated set
      final updatedSet = CharacterSet(
        id: widget.set.id,
        name: _nameController.text.trim(),
        characters: _items,
        description: widget.set.description,
        isWordSet: isWordSet,
        color: widget.set.color,
        source: widget.set.source,
        definitions: widget.set.definitions,
        groupSize: widget.set.groupSize ?? 10,
      );
      
      // Save the updated set
      await _setManager.updateCustomSet(updatedSet);
      
      setState(() {
        _hasUnsavedChanges = false;
        _isLoading = false;
      });
      
      // Notify parent and return
      widget.onSetUpdated?.call();
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
      final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: isDuotone 
                ? duotoneExt?.duotoneColor2
                : Colors.red,
          ),
        );
      }
    }
  }
  
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Discard changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isDuotone 
                  ? duotoneExt?.duotoneColor2
                  : Colors.red,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return shouldDiscard ?? false;
  }
  
  Future<void> _showDeleteDialog() async {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text('Delete "${_nameController.text}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isDuotone 
                  ? duotoneExt?.duotoneColor2
                  : Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      // Delete set logic would go here
      Navigator.of(context).pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDuotone 
            ? Theme.of(context).scaffoldBackgroundColor
            : null,
        appBar: AppBar(
          title: _isEditingName
              ? TextField(
                  controller: _nameController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: isDuotone ? duotoneExt?.duotoneColor2 : null,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Set name',
                    hintStyle: TextStyle(
                      color: isDuotone 
                          ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.5)
                          : null,
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _isEditingName = false;
                      _hasUnsavedChanges = true;
                    });
                  },
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditingName = true;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _nameController.text.isNotEmpty ? _nameController.text : 'Edit Set',
                          style: TextStyle(
                            color: isDuotone ? duotoneExt?.duotoneColor2 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        size: 18,
                        color: isDuotone 
                            ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.6)
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
          backgroundColor: isDuotone 
              ? Theme.of(context).scaffoldBackgroundColor
              : Theme.of(context).colorScheme.surface,
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: TextButton.styleFrom(
                  foregroundColor: isDuotone ? duotoneExt?.duotoneColor2 : Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Save'),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: isDuotone ? duotoneExt?.duotoneColor2 : null,
            labelColor: isDuotone ? duotoneExt?.duotoneColor2 : null,
            unselectedLabelColor: isDuotone 
                ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.5)
                : null,
            tabs: const [
              Tab(text: 'Add', icon: Icon(Icons.add_circle_outline)),
              Tab(text: 'Remove', icon: Icon(Icons.remove_circle_outline)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Add Items
            _buildAddTab(),
            
            // Tab 2: Remove Items
            _buildRemoveTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRemoveTab() {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    
    // Determine view mode based on item count
    final bool useCompactView = _items.length > 20;
    
    return Column(
      children: [
        // Selection controls
        if (_items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  _isSelectionMode 
                      ? '${_selectedIndices.length} selected'
                      : '${_items.length} items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDuotone ? duotoneExt?.duotoneColor2 : null,
                  ),
                ),
                const Spacer(),
                if (_isSelectionMode) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedIndices.length == _items.length) {
                          _selectedIndices.clear();
                        } else {
                          _selectedIndices.clear();
                          for (int i = 0; i < _items.length; i++) {
                            _selectedIndices.add(i);
                          }
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDuotone ? duotoneExt?.duotoneColor2 : null,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(_selectedIndices.length == _items.length ? 'Deselect All' : 'Select All'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectedIndices.isNotEmpty ? _removeSelectedItems : null,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDuotone ? duotoneExt?.duotoneColor2 : Colors.red,
                      foregroundColor: isDuotone 
                          ? Theme.of(context).scaffoldBackgroundColor
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
                // View toggle button for large sets
                if (_items.length > 15)
                  IconButton(
                    icon: Icon(
                      _useListView ? Icons.grid_view : Icons.view_list,
                      color: isDuotone ? duotoneExt?.duotoneColor2 : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _useListView = !_useListView;
                      });
                    },
                    tooltip: _useListView ? 'Grid View' : 'List View',
                  ),
              ],
            ),
          ),
        
        // Grid of items
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Text(
                    'No items in this set',
                    style: TextStyle(
                      color: isDuotone 
                          ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.5)
                          : Colors.grey,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: useCompactView ? 4 : 3,
                      crossAxisSpacing: useCompactView ? 8 : 12,
                      mainAxisSpacing: useCompactView ? 8 : 12,
                      childAspectRatio: useCompactView ? 1.2 : 0.85,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = _selectedIndices.contains(index);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIndices.remove(index);
                            } else {
                              _selectedIndices.add(index);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDuotone 
                                    ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.15)
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15))
                                : (isDuotone
                                    ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.1)
                                    : Theme.of(context).colorScheme.surfaceContainerHighest),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (isDuotone 
                                      ? duotoneExt?.duotoneColor2 ?? Colors.blue
                                      : Theme.of(context).colorScheme.primary)
                                  : (isDuotone
                                      ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.25) ?? Colors.grey
                                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: useCompactView 
                                          ? (item.length == 1 ? 24 : 18)
                                          : (item.length == 1 ? 32 : (item.length <= 3 ? 22 : 16)),
                                      fontWeight: FontWeight.w500,
                                      color: isDuotone 
                                          ? duotoneExt?.duotoneColor2
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              // Selection indicator - always visible
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDuotone 
                                            ? duotoneExt?.duotoneColor2
                                            : Theme.of(context).colorScheme.primary)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDuotone 
                                          ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.8) ?? Colors.pink
                                          : Theme.of(context).colorScheme.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: isDuotone 
                                              ? Theme.of(context).scaffoldBackgroundColor
                                              : Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildAddTab() {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final duotoneExt = Theme.of(context).extension<DuotoneThemeExtension>();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: isDuotone ? 0 : null,
            color: isDuotone 
                ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.2)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDuotone ? duotoneExt?.duotoneColor2 : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter items separated by commas, spaces, or new lines',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDuotone 
                          ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.7)
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addItemController,
                    decoration: InputDecoration(
                      hintText: 'e.g., 你好, 世界, 中国',
                      hintStyle: TextStyle(
                        color: isDuotone 
                            ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.5)
                            : null,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDuotone 
                              ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.3) ?? Colors.grey
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDuotone 
                              ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.3) ?? Colors.grey
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDuotone 
                              ? duotoneExt?.duotoneColor2 ?? Colors.blue
                              : Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: isDuotone ? duotoneExt?.duotoneColor2 : null,
                      fontSize: 16,
                    ),
                    maxLines: 6,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addItem(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Items'),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDuotone ? duotoneExt?.duotoneColor2 : null,
                        foregroundColor: isDuotone 
                            ? Theme.of(context).scaffoldBackgroundColor 
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Current count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDuotone 
                  ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDuotone 
                    ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.3) ?? Colors.grey
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 32,
                  color: isDuotone ? duotoneExt?.duotoneColor2 : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_items.length}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDuotone ? duotoneExt?.duotoneColor2 : null,
                      ),
                    ),
                    Text(
                      'Total Items',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDuotone 
                            ? duotoneExt?.duotoneColor2?.withValues(alpha: 0.7)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}