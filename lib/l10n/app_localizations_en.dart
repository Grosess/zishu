// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zishu';

  @override
  String get practice => 'Practice';

  @override
  String get sets => 'Sets';

  @override
  String get statistics => 'Statistics';

  @override
  String get settings => 'Settings';

  @override
  String get importFromPhoto => 'Import from Photo';

  @override
  String get scanVocabulary => 'Scan Vocabulary';

  @override
  String get selectPhotos => 'Select Photos';

  @override
  String get fromCamera => 'From Camera';

  @override
  String get fromGallery => 'From Gallery';

  @override
  String get practiceGroupSize => 'Practice Group Size';

  @override
  String get practiceGroupDescription =>
      'How many vocabulary terms will be practiced together in each study session';

  @override
  String get practiceGroupExample =>
      'Example: 10 = practice 10 words at a time';

  @override
  String get chinese => 'Chinese';

  @override
  String get pinyin => 'Pinyin';

  @override
  String get english => 'English';

  @override
  String get saveSet => 'Save Set';

  @override
  String get characterSetName => 'Character Set Name';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get englishLanguage => 'English';

  @override
  String get chineseLanguage => '中文';

  @override
  String get welcomeTitle => 'Welcome to Zishu';

  @override
  String get welcomeMessage => 'Please select your preferred language:';

  @override
  String get processing => 'Processing...';

  @override
  String get ocrProcessing => 'Processing image with OCR...';

  @override
  String get downloadingModel =>
      'Downloading language model... This may take a moment.';
}
