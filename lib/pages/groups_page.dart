import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'character_list_page.dart';
import '../services/learning_service.dart';
import '../l10n/app_localizations.dart';

class GroupsPage extends StatefulWidget {
  final String setName;
  final List<String> characters;
  final bool isWordSet;

  const GroupsPage({
    super.key,
    required this.setName,
    required this.characters,
    this.isWordSet = false,
  });

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final LearningService _learningService = LearningService();
  List<String> _learnedCharacters = [];
  int _groupSize = 10;
  int? _selectedSuperGroupIndex;

  @override
  void initState() {
    super.initState();
    _loadGroupSizeFromSettings();
    _loadLearnedStatus();
  }

  Future<void> _loadGroupSizeFromSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyGoal = prefs.getInt('daily_learn_goal') ?? 10;
    setState(() {
      _groupSize = dailyGoal;
    });
  }

  Future<void> _loadLearnedStatus() async {
    final terms = widget.characters.map((item) => _extractTerm(item)).toList();
    final learned = await _learningService.getLearnedCharactersForSet(terms);
    
    if (mounted) {
      setState(() {
        _learnedCharacters = learned;
      });
    }
  }

  // Calculate number of groups
  int get _groupCount => (widget.characters.length / _groupSize).ceil();

  // Calculate super group size based on total characters
  int get _dynamicSuperGroupSize {
    final totalChars = widget.characters.length;
    if (totalChars >= 1000) return 100; // 10 groups of 10
    if (totalChars >= 800) return 80;   // 8 groups of 10
    if (totalChars >= 600) return 60;   // 6 groups of 10
    if (totalChars >= 400) return 40;   // 4 groups of 10
    return 0; // No super groups for sets < 400
  }

  // Check if we should show super groups
  bool get _shouldShowSuperGroups => widget.characters.length >= 400;

  // Calculate number of super groups
  int get _superGroupCount {
    if (!_shouldShowSuperGroups) return 0;
    return (_groupCount * _groupSize / _dynamicSuperGroupSize).ceil();
  }

  // Get groups for a specific super group
  List<int> _getSuperGroupIndices(int superGroupIndex) {
    final groupsPerSuperGroup = _dynamicSuperGroupSize ~/ _groupSize;
    final start = superGroupIndex * groupsPerSuperGroup;
    final end = math.min(start + groupsPerSuperGroup, _groupCount);
    return List.generate(end - start, (i) => start + i);
  }

  // Get characters for a specific group
  List<String> _getGroupCharacters(int groupIndex) {
    final start = groupIndex * _groupSize;
    final end = (start + _groupSize).clamp(0, widget.characters.length);
    return widget.characters.sublist(start, end);
  }

  String _extractTerm(String item) {
    final parenIndex = item.indexOf('(');
    if (parenIndex > 0) {
      return item.substring(0, parenIndex).trim();
    }
    return item.trim();
  }

  Widget _buildGroupCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required int learnedCount,
    required int totalCount,
  }) {
    final progress = totalCount > 0 ? learnedCount / totalCount : 0.0;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            gradient: totalCount > 0 ? LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [progress, progress],
              colors: [
                isSelected
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
              ],
            ) : null,
            color: totalCount == 0 ? (isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Group label with count inline
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (totalCount > 0) // Only show count if totalCount > 0
                      Text(
                        AppLocalizations.of(context)!.itemsCount(totalCount),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Progress text on the right (only if totalCount > 0)
              if (totalCount > 0)
                Text(
                  '$learnedCount/$totalCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.setGroups(widget.setName)),
      ),
      body: CustomScrollView(
        slivers: [
          // Super groups section for large sets
          if (_shouldShowSuperGroups && _selectedSuperGroupIndex == null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // One supergroup per line
                  childAspectRatio: 6.0, // Wide aspect ratio for full width
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final groupIndices = _getSuperGroupIndices(index);
                    
                    // Count learned in this super group
                    int totalLearned = 0;
                    for (final groupIdx in groupIndices) {
                      final groupChars = _getGroupCharacters(groupIdx);
                      totalLearned += groupChars.where((item) {
                        final term = _extractTerm(item);
                        return _learnedCharacters.contains(term) || _learnedCharacters.contains(item);
                      }).length;
                    }
                    
                    // Count total characters for this supergroup
                    int totalCharacters = 0;
                    for (final groupIdx in groupIndices) {
                      final groupChars = _getGroupCharacters(groupIdx);
                      totalCharacters += groupChars.length;
                    }
                    
                    return _buildGroupCard(
                      label: AppLocalizations.of(context)!.supergroupNumber(index + 1),
                      isSelected: false,
                      learnedCount: totalLearned,
                      totalCount: totalCharacters, // Show number of characters for progress
                      onTap: () {
                        setState(() {
                          _selectedSuperGroupIndex = index;
                        });
                      },
                    );
                  },
                  childCount: _superGroupCount,
                ),
              ),
            ),
          
          // Regular groups section
          if ((_selectedSuperGroupIndex != null || !_shouldShowSuperGroups) && widget.characters.length > _groupSize)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // One group per line
                  childAspectRatio: 6.0, // Wide aspect ratio for full width
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Determine which groups to show based on super group selection
                    final groupsToShow = _selectedSuperGroupIndex != null
                        ? _getSuperGroupIndices(_selectedSuperGroupIndex!)
                        : List.generate(_groupCount, (i) => i);
                    
                    if (index == 0 && _selectedSuperGroupIndex != null) {
                      // Back button when in super-group
                      return _buildGroupCard(
                        label: AppLocalizations.of(context)!.backToSupergroups,
                        isSelected: false,
                        learnedCount: 0,
                        totalCount: 0, // Back button doesn't need count
                        onTap: () {
                          setState(() {
                            _selectedSuperGroupIndex = null;
                          });
                        },
                      );
                    } else {
                      final actualIndex = _selectedSuperGroupIndex != null ? index - 1 : index;
                      if (actualIndex >= groupsToShow.length) return const SizedBox();
                      
                      final groupIndex = groupsToShow[actualIndex];
                      final groupChars = _getGroupCharacters(groupIndex);
                      
                      // Count learned in this group
                      final learnedCount = groupChars.where((item) {
                        final term = _extractTerm(item);
                        return _learnedCharacters.contains(term) || _learnedCharacters.contains(item);
                      }).length;
                      
                      return _buildGroupCard(
                        label: AppLocalizations.of(context)!.groupNumber(groupIndex + 1),
                        isSelected: false,
                        learnedCount: learnedCount,
                        totalCount: groupChars.length,
                        onTap: () {
                          // Navigate to new page with just this group's characters
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CharacterListPage(
                                setName: AppLocalizations.of(context)!.setGroupNumber(widget.setName, groupIndex + 1),
                                characters: groupChars,
                                isWordSet: widget.isWordSet,
                                isCustomSet: false,
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                  childCount: _selectedSuperGroupIndex != null 
                      ? _getSuperGroupIndices(_selectedSuperGroupIndex!).length + 1  // +1 for back button
                      : _groupCount, // No back button for regular groups
                ),
              ),
            ),
          
          // Message when no groups are needed
          if (widget.characters.length <= _groupSize)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.apps_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noGroupsNeeded,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This set has ${widget.characters.length} characters, which is small enough to practice all at once.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}