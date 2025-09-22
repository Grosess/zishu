import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../generated/l10n.dart';

class LanguageSelectionDialog extends StatelessWidget {
  final LanguageService languageService;
  final bool isWelcome;

  const LanguageSelectionDialog({
    Key? key,
    required this.languageService,
    this.isWelcome = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isWelcome ? S.of(context).welcomeTitle : S.of(context).selectLanguage,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWelcome)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(S.of(context).welcomeMessage),
            ),
          ...LanguageService.supportedLocales.map((locale) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Radio<Locale>(
                value: locale,
                groupValue: languageService.locale,
                onChanged: (value) {
                  if (value != null) {
                    _selectLanguage(context, value);
                  }
                },
              ),
              title: Text(
                languageService.getLanguageName(locale),
                style: const TextStyle(fontSize: 16),
              ),
              onTap: () => _selectLanguage(context, locale),
            );
          }),
        ],
      ),
      actions: [
        if (!isWelcome)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
      ],
    );
  }

  void _selectLanguage(BuildContext context, Locale locale) async {
    await languageService.setLanguage(locale);
    
    if (isWelcome) {
      await languageService.completeFirstLaunch();
    }
    
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}