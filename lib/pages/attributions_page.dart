import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart' show DuotoneThemeExtension;

class AttributionsPage extends StatelessWidget {
  const AttributionsPage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDuotone = Theme.of(context).extension<DuotoneThemeExtension>()?.isDuotoneTheme == true;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attributions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MakeMeAHanzi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stroke order data and character decomposition',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  const Text('Copyright (c) 2016 Shaunak Kishore'),
                  const Text('Licensed under LGPL-3.0'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _launchUrl('https://github.com/skishore/makemeahanzi'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View on GitHub'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CC-CEDICT',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chinese-English dictionary data',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  const Text('Copyright (c) 2024 MDBG'),
                  const Text('Licensed under CC BY-SA 4.0'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _launchUrl('https://www.mdbg.net/chinese/dictionary?page=cc-cedict'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Visit MDBG'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unicode Unihan Database',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Character information and radical data',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  const Text('Copyright (c) 1991-2024 Unicode, Inc.'),
                  const Text('Licensed under the Unicode License Agreement'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _launchUrl('https://www.unicode.org/charts/unihan.html'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Learn More'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: isDuotone 
                ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2!.withOpacity(0.1)
                : Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDuotone 
                            ? Theme.of(context).extension<DuotoneThemeExtension>()!.duotoneColor2
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Open Source',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Zishu is built with Flutter and uses various open-source libraries. '
                    'We are grateful to all the contributors who make these resources available.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}