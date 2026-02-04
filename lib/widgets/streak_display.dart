import 'package:flutter/material.dart';
import '../services/streak_service.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';

class StreakDisplay extends StatefulWidget {
  final bool showOnlyIcon;
  final int? todayProgress;
  final int? dailyGoal;
  
  const StreakDisplay({
    super.key,
    this.showOnlyIcon = false,
    this.todayProgress,
    this.dailyGoal,
  });

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay> {
  final StreakService _streakService = StreakService();
  StreakData? _streakData;
  
  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }
  
  @override
  void didUpdateWidget(StreakDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when todayProgress or dailyGoal changes
    if (oldWidget.todayProgress != widget.todayProgress || 
        oldWidget.dailyGoal != widget.dailyGoal) {
      _loadStreakData();
    }
  }
  
  Future<void> _loadStreakData() async {
    final data = await _streakService.getStreakData();
    if (mounted) {
      setState(() {
        _streakData = data;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_streakData == null) {
      return const SizedBox.shrink();
    }
    
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final primaryColor = isDuotone 
        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
        : Theme.of(context).colorScheme.primary;
    
    final todayProg = widget.todayProgress ?? _streakData!.todayProgress;
    final dailyG = widget.dailyGoal ?? _streakData!.dailyGoal;
    final isGoalMet = todayProg >= dailyG;
    final streakColor = isGoalMet ? primaryColor : primaryColor.withOpacity(0.5);
    
    if (widget.showOnlyIcon) {
      // Compact display for app bar
      return InkWell(
        onTap: () => _showStreakDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: streakColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: streakColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGoalMet ? Icons.local_fire_department : Icons.local_fire_department_outlined,
                size: 20,
                color: streakColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${_streakData!.currentStreak}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: streakColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Full display for progress page
    return Card(
      margin: EdgeInsets.zero, // Remove default Card margin
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showStreakDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 28,
                    color: streakColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.dailyStreak,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: streakColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: streakColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_streakData!.currentStreak}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: streakColor,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.currentStreak,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_streakData!.longestStreak}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryColor.withOpacity(0.8),
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.bestStreak,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.todaysProgress,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${widget.todayProgress ?? _streakData!.todayProgress}/${widget.dailyGoal ?? _streakData!.dailyGoal}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: ((widget.todayProgress ?? _streakData!.todayProgress) / (widget.dailyGoal ?? _streakData!.dailyGoal)).clamp(0.0, 1.0),
                    backgroundColor: primaryColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showStreakDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Streak Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.currentStreak}: ${_streakData!.currentStreak} days',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.bestStreak}: ${_streakData!.longestStreak} days',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Learn ${_streakData!.dailyGoal} new characters today to maintain your streak',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your progress goal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}