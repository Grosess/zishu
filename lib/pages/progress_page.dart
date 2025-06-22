import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../services/statistics_service.dart';
import '../main.dart' show DuotoneThemeExtension;
import '../widgets/streak_display.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => ProgressPageState();
}

class ProgressPageState extends State<ProgressPage> with TickerProviderStateMixin {
  final StatisticsService _statsService = StatisticsService();
  final ScrollController _scrollController = ScrollController();
  late SharedPreferences _prefs;
  
  // Statistics
  int _totalCharactersLearned = 0;
  int _totalWordsLearned = 0;
  Duration _totalStudyTime = Duration.zero;
  int _dailyCharactersStudied = 0;
  Duration _dailyStudyTime = Duration.zero;
  
  // Goals
  int _characterGoal = 100;
  DateTime? _goalDeadline;
  int _dailyPracticeGoal = 20;
  
  // Progress
  double _dailyProgress = 0.0;
  int _charactersNeededToday = 0;
  int _dailyCharactersLearned = 0;
  int _currentStreak = 0;
  
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _progressAnimationController;
  late AnimationController _percentageAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _percentageAnimation;
  double _lastProgress = 0.0;
  double _lastPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _percentageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOut,
    ));
    
    _percentageAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _percentageAnimationController,
      curve: Curves.easeOut,
    ));
    
    _loadData();
  }
  
  @override
  void didUpdateWidget(ProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when widget updates
    loadStatistics();
  }
  
  @override
  void dispose() {
    _progressAnimationController.dispose();
    _percentageAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load goals
    setState(() {
      final loadedGoal = _prefs.getInt('character_goal') ?? 100;
      // Ensure goal doesn't exceed 5 digits
      _characterGoal = loadedGoal > 99999 ? 99999 : loadedGoal;
      _dailyPracticeGoal = _prefs.getInt('daily_practice_goal') ?? 20;
      
      // Load deadline or set default to 30 days from now
      final deadlineString = _prefs.getString('goal_deadline');
      if (deadlineString != null) {
        _goalDeadline = DateTime.parse(deadlineString);
      } else {
        _goalDeadline = DateTime.now().add(const Duration(days: 30));
      }
    });
    
    // Load statistics
    await loadStatistics();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> loadStatistics() async {
    // Load real statistics
    final totalStats = await _statsService.getTotalStats();
    final dailyStats = await _statsService.getDailyStats(null);
    final learnedCharacters = await _statsService.getLearnedCharacters();
    final learnedWords = await _statsService.getLearnedWords();
    final streak = await _statsService.getCurrentStreak();
    
    // Calculate actual characters learned today by checking timestamps
    int todayLearned = 0;
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Check learned character timestamps
    for (final char in learnedCharacters) {
      final timestamp = _prefs.getString('learned_character_$char');
      if (timestamp != null) {
        final learnedDate = DateTime.parse(timestamp);
        final learnedKey = '${learnedDate.year}-${learnedDate.month.toString().padLeft(2, '0')}-${learnedDate.day.toString().padLeft(2, '0')}';
        if (learnedKey == todayKey) {
          todayLearned++;
        }
      }
    }
    
    // Check learned word timestamps
    for (final word in learnedWords) {
      final timestamp = _prefs.getString('learned_word_$word');
      if (timestamp != null) {
        final learnedDate = DateTime.parse(timestamp);
        final learnedKey = '${learnedDate.year}-${learnedDate.month.toString().padLeft(2, '0')}-${learnedDate.day.toString().padLeft(2, '0')}';
        if (learnedKey == todayKey) {
          todayLearned++;
        }
      }
    }
    
    setState(() {
      _totalCharactersLearned = learnedCharacters.length;
      _totalWordsLearned = learnedWords.length;
      _totalStudyTime = totalStats.totalTime;
      _dailyCharactersStudied = dailyStats.charactersStudied;
      _dailyCharactersLearned = todayLearned; // Use actual count
      _dailyStudyTime = dailyStats.totalTime;
      _currentStreak = streak;
      
      // Calculate days remaining
      final now = DateTime.now();
      final daysRemaining = math.max(1, _goalDeadline!.difference(now).inDays + 1);
      
      // Calculate remaining characters to learn
      final charactersRemaining = math.max(0, _characterGoal - _totalCharactersLearned);
      
      // Calculate how many characters needed per day to reach goal
      final charactersPerDay = (charactersRemaining / daysRemaining).ceil();
      
      // Today's target is simply the daily rate
      _charactersNeededToday = charactersPerDay;
      _dailyPracticeGoal = charactersPerDay;
      
      // Save the calculated daily goal for the streak service to use
      _prefs.setInt('daily_practice_goal', charactersPerDay);
      
      // Daily progress is based on today's target
      _dailyProgress = _charactersNeededToday > 0 
          ? _dailyCharactersLearned / _charactersNeededToday
          : 1.0;
    });
    
    // Animate progress changes
    final newProgress = _totalCharactersLearned.toDouble();
    final newPercentage = (_totalCharactersLearned / _characterGoal) * 100;
    
    _progressAnimation = Tween<double>(
      begin: _lastProgress,
      end: newProgress,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOut,
    ));
    
    _percentageAnimation = Tween<double>(
      begin: _lastPercentage,
      end: newPercentage,
    ).animate(CurvedAnimation(
      parent: _percentageAnimationController,
      curve: Curves.easeOut,
    ));
    
    _progressAnimationController.forward(from: 0);
    _percentageAnimationController.forward(from: 0);
    
    _lastProgress = newProgress;
    _lastPercentage = newPercentage;
    
    // Check if goal is reached
    if (_totalCharactersLearned >= _characterGoal && !_prefs.containsKey('goal_congratulated_$_characterGoal')) {
      // Show congratulations after a short delay
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _showCongratulationsDialog();
          _prefs.setBool('goal_congratulated_$_characterGoal', true);
        }
      });
    }
  }

  Future<void> _saveGoal(String key, int value) async {
    await _prefs.setInt(key, value);
    loadStatistics(); // Recalculate progress
  }

  void _showCongratulationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.celebration, 
              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                ? Theme.of(context).colorScheme.primary
                : Colors.amber,
              size: 32
            ),
            const SizedBox(width: 12),
            const Text('Congratulations!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              size: 80,
              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                ? Theme.of(context).colorScheme.primary
                : Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'You\'ve reached your goal of $_characterGoal characters!',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Total characters learned: $_totalCharactersLearned',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to set a new goal?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showGoalDialog();
            },
            icon: const Icon(Icons.flag),
            label: const Text('Set New Goal'),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog() {
    final goalController = TextEditingController(text: _characterGoal.toString());
    DateTime selectedDate = _goalDeadline ?? DateTime.now().add(const Duration(days: 30));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Learning Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: goalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Characters',
                  hintText: 'e.g., 100',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (value) {
                  final num = int.tryParse(value) ?? 0;
                  if (num > 99999) {
                    goalController.text = '99999';
                    goalController.selection = TextSelection.fromPosition(
                      TextPosition(offset: goalController.text.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text('Target Date', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null && picked != selectedDate) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final goal = int.tryParse(goalController.text) ?? _characterGoal;
                
                // Limit goal to 5 digits (99999 max)
                final limitedGoal = goal > 99999 ? 99999 : goal;
                
                if (goal > 99999) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal limited to 99,999 characters maximum'),
                    ),
                  );
                }
                
                setState(() {
                  _characterGoal = limitedGoal;
                  _goalDeadline = selectedDate;
                });
                
                _saveGoal('character_goal', limitedGoal);
                _prefs.setString('goal_deadline', selectedDate.toIso8601String());
                loadStatistics(); // Recalculate
                
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPracticeGoalDialog() {
    final controller = TextEditingController(text: _dailyPracticeGoal.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Practice Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Practice Target',
            hintText: 'e.g., 20',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final goal = int.tryParse(controller.text) ?? _dailyPracticeGoal;
              
              setState(() {
                _dailyPracticeGoal = goal;
              });
              
              _saveGoal('daily_practice_goal', goal);
              
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Progress towards goal
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(200, 200),
                          painter: SpeedometerPainter(
                            value: _progressAnimation.value.round(),
                            maxValue: _characterGoal,
                            color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                              ? Theme.of(context).colorScheme.primary
                              : (_totalCharactersLearned >= _characterGoal ? Colors.amber : Colors.green),
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _percentageAnimation,
                          builder: (context, child) {
                            return Text(
                              '${_percentageAnimation.value.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            );
                          },
                        ),
                        Text(
                          'of $_characterGoal goal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _showGoalDialog,
                          child: const Text('Set Goal'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Total characters learned - now underneath the goal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? [
                            Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ]
                        : [
                            Colors.amber.withOpacity(0.2),
                            Colors.orange.withOpacity(0.1),
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                        ? Theme.of(context).colorScheme.primary
                        : Colors.amber,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _totalCharactersLearned.toString(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                            ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! // Use duotone foreground
                            : Colors.amber,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.emoji_events,
                        size: 36,
                        color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2! // Use duotone foreground
                          : Colors.amber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Characters Learned',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // Total study time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer, 
                  color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Study Time: ${_formatDuration(_totalStudyTime)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress meters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Characters learned today
                Expanded(
                  child: _buildProgressMeter(
                    title: 'Today\'s Learn',
                    current: _dailyCharactersLearned,
                    total: _charactersNeededToday,
                    icon: Icons.school,
                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).colorScheme.primary
                      : Colors.blue,
                    onTap: null,
                  ),
                ),
                const SizedBox(width: 12),
                // Characters reviewed/practiced today
                Expanded(
                  child: _buildProgressMeter(
                    title: 'Today\'s Review',
                    current: _dailyCharactersStudied,
                    total: _dailyPracticeGoal,
                    icon: Icons.edit,
                    color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                      ? Theme.of(context).colorScheme.primary
                      : Colors.green,
                    onTap: _showPracticeGoalDialog,
                  ),
                ),
              ],
            ),
          ),
          
          // Daily statistics section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Time stat - custom styled
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true 
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                            offset: Offset(0, 2),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? Theme.of(context).colorScheme.primary
                          : Colors.indigo,
                        size: 48,
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Time',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            _formatDuration(_totalStudyTime),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                                ? Theme.of(context).colorScheme.primary
                                : Colors.indigo,
                              letterSpacing: -1,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Daily stats cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.calendar_today,
                        title: 'Cards Studied',
                        value: _dailyCharactersStudied.toString(),
                        color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? Theme.of(context).colorScheme.primary
                          : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.access_time,
                        title: 'Time Today',
                        value: _formatDuration(_dailyStudyTime),
                        color: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true
                          ? Theme.of(context).colorScheme.primary
                          : Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Streak Display with synchronized progress
                StreakDisplay(
                  showOnlyIcon: false,
                  todayProgress: _dailyCharactersLearned,
                  dailyGoal: _dailyPracticeGoal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMeter({
    required String title,
    required int current,
    required int total,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDuotone 
          ? Theme.of(context).colorScheme.surface
          : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDuotone 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : color.withOpacity(0.3)
        ),
        boxShadow: isDuotone
          ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                offset: Offset(0, 1),
                blurRadius: 4,
              ),
            ]
          : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: isDuotone ? Theme.of(context).colorScheme.primary : color),
              if (onTap != null)
                GestureDetector(
                  onTap: onTap,
                  child: Icon(Icons.settings, size: 14, color: isDuotone ? Theme.of(context).colorScheme.primary : color),
                ),
            ],
          ),
          const SizedBox(height: 2),
          // Fraction display
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: current.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDuotone ? Theme.of(context).colorScheme.primary : color,
                  ),
                ),
                TextSpan(
                  text: ' / $total',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDuotone 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
                      : color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Progress bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: isDuotone 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDuotone ? Theme.of(context).colorScheme.primary : color
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDuotone 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true 
          ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                offset: Offset(0, 2),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ]
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

// Custom painter for the speedometer
class SpeedometerPainter extends CustomPainter {
  final int value;
  final int maxValue;
  final Color color;

  SpeedometerPainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Background arc
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi * 1.25,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    
    final progress = (value / maxValue).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi * 1.25,
      math.pi * 1.5 * progress,
      false,
      progressPaint,
    );
    
    // Tick marks
    final tickPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2;
    
    for (int i = 0; i <= 10; i++) {
      final angle = -math.pi * 1.25 + (math.pi * 1.5 * i / 10);
      final tickLength = i % 5 == 0 ? 15 : 10;
      
      final startX = center.dx + (radius - 25) * math.cos(angle);
      final startY = center.dy + (radius - 25) * math.sin(angle);
      final endX = center.dx + (radius - 25 - tickLength) * math.cos(angle);
      final endY = center.dy + (radius - 25 - tickLength) * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}