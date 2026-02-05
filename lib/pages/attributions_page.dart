import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart' show DuotoneThemeExtension;
import '../l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.attributions),
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
                  Text(
                    AppLocalizations.of(context)!.strokeOrderData,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.copyrightShaunak),
                  Text(AppLocalizations.of(context)!.licensedLGPL),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _launchUrl('https://github.com/skishore/makemeahanzi'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(AppLocalizations.of(context)!.viewOnGitHub),
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
                  Text(
                    AppLocalizations.of(context)!.dictionaryData,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.copyrightMDBG),
                  Text(AppLocalizations.of(context)!.licensedCCBY),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _launchUrl('https://www.mdbg.net/chinese/dictionary?page=cc-cedict'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(AppLocalizations.of(context)!.visitMDBG),
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
                  Text(
                    AppLocalizations.of(context)!.characterInfoData,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.copyrightUnicode),
                  Text(AppLocalizations.of(context)!.licensedUnicode),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _launchUrl('https://www.unicode.org/charts/unihan.html'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(AppLocalizations.of(context)!.learnMore),
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
                        AppLocalizations.of(context)!.openSource,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.openSourceDescription,
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