import 'package:flutter/material.dart';
import '../main.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    final primaryColor = isDuotone 
        ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!
        : Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use Zishu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Welcome to Zishu!',
              'Zishu helps you master Chinese character writing through practice and repetition. Follow the stroke order to learn characters correctly.',
              Icons.waving_hand,
              primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Getting Started',
              '1. Choose a character set from the Sets tab\n'
              '2. Tap "Learn All" to practice new characters\n'
              '3. Write each stroke in the correct order\n'
              '4. Complete all strokes to learn a character',
              Icons.rocket_launch,
              primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Practice Modes',
              '• **Learning Mode**: Practice new characters with hints\n'
              '• **Practice All**: Test yourself on learned characters\n'
              '• **Endless Practice**: Review all learned characters continuously',
              Icons.school,
              primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Writing Characters',
              '• Follow the stroke order (shown by numbers)\n'
              '• Draw smoothly from start to end\n'
              '• After 2 wrong attempts, a hint will appear\n'
              '• Complete all strokes to finish a character',
              Icons.edit,
              primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Daily Streak',
              '• Complete your daily goal to maintain your streak\n'
              '• Tap the streak icon (🔥) to adjust your daily goal\n'
              '• Track your progress in the Progress tab\n'
              '• Keep practicing daily to build a long streak!',
              Icons.local_fire_department,
              primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Character Sets',
              '• **Sample Sets**: Pre-made sets to get started\n'
              '• **Custom Sets**: Create your own character lists\n'
              '• **Organize**: Create folders to group your sets\n'
              '• **Progress**: Green checkmark shows completed sets',
              Icons.folder,
              primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Tips for Success',
              '• Practice daily, even for just 5-10 minutes\n'
              '• Focus on stroke order accuracy\n'
              '• Review characters you find difficult\n'
              '• Use "Create set from incorrect" after practice\n'
              '• Check character info to learn meanings',
              Icons.lightbulb,
              primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Themes & Customization',
              '• Choose from Light, Dark, or Duotone themes\n'
              '• Duotone themes use only two colors\n'
              '• Customize your profile with a photo\n'
              '• Adjust writing sensitivity in settings',
              Icons.palette,
              primaryColor,
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              'Progress Tracking',
              '• View your total characters learned\n'
              '• Track daily practice time\n'
              '• Monitor your streak and goals\n'
              '• Export your practice history',
              Icons.trending_up,
              primaryColor,
            ),
            
            const SizedBox(height: 32),
            
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 32,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Happy Learning!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remember: Consistent practice is the key to mastering Chinese characters. Start with a few characters each day and gradually increase as you improve.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.only(left: 44),
          child: _buildFormattedText(context, content),
        ),
      ],
    );
  }
  
  Widget _buildFormattedText(BuildContext context, String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;
    
    for (final match in regex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: Theme.of(context).textTheme.bodyMedium,
        ));
      }
      
      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // Add any remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: Theme.of(context).textTheme.bodyMedium,
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}