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
  String get home => 'Home';

  @override
  String get sets => 'Sets';

  @override
  String get progress => 'Progress';

  @override
  String get settings => 'Settings';

  @override
  String get characterSets => 'Character Sets';

  @override
  String get builtIn => 'Built-in';

  @override
  String get custom => 'Custom';

  @override
  String get learn => 'Learn';

  @override
  String get practice => 'Practice';

  @override
  String get viewAll => 'View All';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get rename => 'Rename';

  @override
  String get select => 'Select';

  @override
  String get editSet => 'Edit Set';

  @override
  String get deleteSet => 'Delete Set';

  @override
  String get renameSet => 'Rename Set';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get discardChanges => 'Discard Changes?';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get discard => 'Discard';

  @override
  String get markAllAsLearned => 'Mark All as Learned';

  @override
  String markAllAsLearnedConfirm(int count, String type, String name) {
    return 'Do you really want to mark all $count $type in \"$name\" as learned?\n\nYou will not be able to undo this action.';
  }

  @override
  String get words => 'Words';

  @override
  String get characters => 'Characters';

  @override
  String get items => 'items';

  @override
  String get totalItems => 'Total Items';

  @override
  String get cards => 'cards';

  @override
  String get selected => 'selected';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get addItems => 'Add Items';

  @override
  String get enterItems =>
      'Enter items separated by commas, spaces, or new lines';

  @override
  String get exampleItems => 'e.g., 你好, 世界, 中国';

  @override
  String get setName => 'Set name';

  @override
  String get enterNewName => 'Enter new name';

  @override
  String createdFrom(String source) {
    return 'Created from: $source';
  }

  @override
  String progressLabel(int percent) {
    return 'Progress: $percent%';
  }

  @override
  String get noItemsInSet => 'No items in this set';

  @override
  String get cannotSaveEmptySet => 'Cannot save an empty set';

  @override
  String deleteSetConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get createNewSet => 'Create New Set';

  @override
  String get enterCharacters => 'Enter characters or words';

  @override
  String get importFromText => 'Import from text';

  @override
  String get theme => 'Theme';

  @override
  String get duotone => 'Duotone';

  @override
  String get classicFixed => 'Classic (Fixed)';

  @override
  String get chooseStrokeType => 'Choose Stroke Type';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get englishLanguage => 'English';

  @override
  String get chineseLanguage => '中文';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get duotoneMode => 'Duotone Mode';

  @override
  String get green => 'Green';

  @override
  String get red => 'Red';

  @override
  String get blue => 'Blue';

  @override
  String get purple => 'Purple';

  @override
  String get orange => 'Orange';

  @override
  String get pink => 'Pink';

  @override
  String get gold => 'Gold';

  @override
  String get black => 'Black';

  @override
  String get white => 'White';

  @override
  String get gridView => 'Grid View';

  @override
  String get listView => 'List View';

  @override
  String get allItemsLearned => 'All items in this set have been learned!';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get searchSets => 'Search sets...';

  @override
  String get noSetsFound => 'No sets found';

  @override
  String get searchAdditionalSets => 'Search additional sets to add...';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Developer';

  @override
  String get welcomeTitle => 'Welcome to Zishu';

  @override
  String get welcomeMessage => 'Please select your preferred language:';

  @override
  String markedItemsAsLearned(int count) {
    return 'Marked $count items as learned';
  }

  @override
  String deletedSet(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get changeColor => 'Change Color';

  @override
  String get moveToFolder => 'Move to Folder';

  @override
  String get mergeWithAnotherSet => 'Merge with Another Set';

  @override
  String countSelected(int count) {
    return '$count selected';
  }

  @override
  String countItems(int count) {
    return '$count items';
  }

  @override
  String get charactersBy => 'characters by';

  @override
  String perDay(int count) {
    return '$count per day';
  }

  @override
  String get there => 'there';

  @override
  String get ahead => 'ahead';

  @override
  String get behind => 'behind';

  @override
  String countAhead(int count) {
    return '$count ahead';
  }

  @override
  String countBehind(int count) {
    return '$count behind';
  }

  @override
  String get endlessPractice => 'Endless Practice';

  @override
  String practiceAllLearned(int count) {
    return 'Practice all $count learned items';
  }

  @override
  String get searchCharacters => 'Search Characters';

  @override
  String get findByPinyin => 'Find by pinyin, Chinese or English';

  @override
  String get recentSets => 'Recent Sets';

  @override
  String get noRecentSets => 'No recent practice sets.';

  @override
  String get startPracticingSets => 'Start practicing from the Sets tab!';

  @override
  String get sessionSummary => 'Session Summary';

  @override
  String get practiceIncorrect => 'Practice Incorrect';

  @override
  String get createSet => 'Create Set';

  @override
  String get done => 'Done';

  @override
  String get nameYourPracticeSet => 'Name Your Practice Set';

  @override
  String get noLearnedItemsFound =>
      'No learned items found. Please learn some characters first!';

  @override
  String get couldNotOpenFeedback => 'Could not open feedback form';

  @override
  String get noValidCharactersFound => 'No valid characters found for practice';

  @override
  String get showGroups => 'Show Groups';

  @override
  String get todaysLearn => 'Today\'s Learn';

  @override
  String get todaysReview => 'Today\'s Review';

  @override
  String get totalTime => 'Total Time';

  @override
  String get todaysProgress => 'Today\'s Progress';

  @override
  String get cardsStudied => 'Cards Studied';

  @override
  String get timeToday => 'Time Today';

  @override
  String get dailyStreak => 'Daily Streak';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get verbs => 'Verbs';

  @override
  String get dailyActivities => 'Daily Activities';

  @override
  String get places => 'Places';

  @override
  String get moreComingSoon => 'More coming soon...';

  @override
  String andMoreCount(int count) {
    return '... and $count more';
  }

  @override
  String get noCustomSets => 'No Custom Sets';

  @override
  String get createCustomSet => 'Create Custom Set';

  @override
  String get removeFromBuiltin => 'Remove from Built-in';

  @override
  String get deleteCustomSet => 'Delete Custom Set';

  @override
  String get createFolder => 'Create Folder';

  @override
  String get renameFolder => 'Rename Folder';

  @override
  String get deleteFolder => 'Delete Folder';

  @override
  String get chooseColor => 'Choose Color';

  @override
  String get mergeSets => 'Merge Sets';

  @override
  String get confirmMerge => 'Confirm Merge';

  @override
  String get noFolder => 'No Folder';

  @override
  String get allItemsLearnedMessage =>
      'All items in this set have been learned!';

  @override
  String get noLearnedItemsMessage =>
      'No learned items in this set yet. Use \"Learn\" first!';

  @override
  String get continueButton => 'Continue';

  @override
  String get someItemsUnavailable => 'Some items unavailable';

  @override
  String ofGoal(Object goal) {
    return 'of $goal goal';
  }

  @override
  String get setGoalButton => 'Set Goal';

  @override
  String get totalCharactersLearned => 'Total Characters Learned';

  @override
  String get totalStudyTime => 'Total Study Time';

  @override
  String minutesShort(Object count) {
    return '${count}m';
  }

  @override
  String hoursShort(Object count) {
    return '${count}h';
  }

  @override
  String daysShort(Object count) {
    return '${count}d';
  }

  @override
  String setsCount(Object count) {
    return '$count sets';
  }

  @override
  String setCount(Object count) {
    return '$count set';
  }

  @override
  String get searchCharactersHint => 'Search characters...';

  @override
  String get endless => 'Endless';

  @override
  String get teal => 'Teal';

  @override
  String get lightPink => 'Light Pink';

  @override
  String get hotPink => 'Hot Pink';

  @override
  String get blueGreen => 'Blue Green';

  @override
  String get themeColor => 'Theme Color';

  @override
  String get practiceSettings => 'Practice Settings';

  @override
  String get handwritingMode => 'Handwriting Mode';

  @override
  String get handwritingModeDesc =>
      'Draw freely without stroke guidance, then self-assess';

  @override
  String get showGrid => 'Show Grid';

  @override
  String get showGridDesc => 'Display grid lines in the practice area';

  @override
  String get showGuideByDefault => 'Show Guide by Default';

  @override
  String get showGuideDesc => 'Show character outline in learning mode';

  @override
  String get strokeWidth => 'Stroke Width';

  @override
  String get strokeColor => 'Stroke Color';

  @override
  String get strokeType => 'Stroke Type';

  @override
  String get strokeAppearance => 'Stroke Appearance';

  @override
  String get autoPronounce => 'Auto-Pronounce Chinese';

  @override
  String get autoPronounceDesc => 'Automatically speak characters and words';

  @override
  String get cardsPerGroup => 'Cards Per Group';

  @override
  String cardsPerGroupDesc(int count) {
    return '$count characters per group';
  }

  @override
  String get attributions => 'Attributions';

  @override
  String get attributionsDesc => 'Third-party licenses and credits';

  @override
  String get swapColors => 'Swap Colors';

  @override
  String get swapColorsDesc => 'Swap background and accent colors';

  @override
  String get hintColor => 'Hint Color';

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String get charactersPerDay => 'characters per day';

  @override
  String get dataRecoveryTitle => 'Data Recovery Notice';

  @override
  String dataRecoverySuccess(int count) {
    return 'Successfully recovered $count sets from backup';
  }

  @override
  String get dataLoadError => 'Error Loading Sets';

  @override
  String dataLoadErrorMessage(int recovered, int total) {
    return 'Some sets could not be loaded due to corrupted data. Recovered $recovered out of $total sets.';
  }

  @override
  String get dataParseError =>
      'Failed to load custom sets. Data may be corrupted. Attempting recovery from backup...';

  @override
  String dataRecoveryFromBackup(int count) {
    return 'Recovered data from backup! $count sets restored.';
  }

  @override
  String get noBackupAvailable =>
      'No backup available. Please report this issue if you lost data.';

  @override
  String get dataSaveWarning =>
      'Warning: Unable to save changes. Please try again or contact support if the problem persists.';

  @override
  String get ok => 'OK';

  @override
  String get viewDetails => 'View Details';

  @override
  String goodEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String goodNight(String name) {
    return 'Good night, $name';
  }

  @override
  String get keepUpTheGreatWork => 'Keep up the great work!';

  @override
  String get writingMode => 'Writing Mode';

  @override
  String get writingModeNormal => 'Stroke by Stroke';

  @override
  String get writingModeNormalDesc => 'Follow stroke order with guidance';

  @override
  String get writingModeFree => 'Free Draw';

  @override
  String get writingModeFreeDesc => 'Draw freely without stroke guidance';

  @override
  String get showStrokeAnimation => 'Show Stroke Animation';

  @override
  String get showStrokeAnimationDesc => 'Animate the correct stroke path';

  @override
  String get showRadicalAnalysis => 'Show Radical Analysis';

  @override
  String get showRadicalAnalysisDesc => 'Display character radical breakdown';

  @override
  String get beta => 'Beta';

  @override
  String get hapticFeedback => 'Haptic Feedback';

  @override
  String get hapticFeedbackDesc => 'Vibrate on interactions';

  @override
  String get strokeLeniency => 'Stroke Leniency';

  @override
  String get strokeLeniencyDesc => 'How strict stroke validation is';

  @override
  String get mostMissed => 'Most Missed';

  @override
  String get errorRate => 'error rate';

  @override
  String get wrong => 'Wrong';

  @override
  String get right => 'Right';

  @override
  String get attempts => 'Attempts';

  @override
  String get dataAndProgress => 'Data & Progress';

  @override
  String get dataBackup => 'Data Backup';

  @override
  String get practiceHistory => 'Practice History';

  @override
  String get markAsLearned => 'Mark as Learned';

  @override
  String get giveFeedback => 'Give Feedback';

  @override
  String get profile => 'Profile';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get howToUseZishu => 'How to Use Zishu';

  @override
  String get howToUseZishuTutorial => 'How to Use Zishu Tutorial';

  @override
  String get enterFolderName => 'Enter folder name';

  @override
  String get folderName => 'Folder Name';

  @override
  String get hours => 'hours';

  @override
  String get minutes => 'minutes';

  @override
  String get seconds => 'seconds';

  @override
  String get hour => 'hour';

  @override
  String get minute => 'minute';

  @override
  String get second => 'second';

  @override
  String get usingDuotoneForeground => 'Using Duotone Foreground';

  @override
  String get pixels => 'pixels';

  @override
  String get auto => 'Auto';

  @override
  String get strokesConvertToFont => 'Strokes convert to font after drawing';

  @override
  String get exportData => 'Export Data';

  @override
  String get saveProgressToShare =>
      'Save your progress to share with other devices';

  @override
  String get exportDataButton => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get restoreProgress => 'Restore your progress from another device';

  @override
  String get pasteExportedData => 'Paste exported data here';

  @override
  String get importDataButton => 'Import Data';

  @override
  String get howItWorks => 'How it works:';

  @override
  String get exportDataStep1 => '1. Export your data on one device';

  @override
  String get exportDataStep2 => '2. Copy the exported text';

  @override
  String get exportDataStep3 =>
      '3. Send it to your other device (email, message, etc.)';

  @override
  String get exportDataStep4 => '4. Paste and import on the other device';

  @override
  String get backupNote =>
      'Note: This is a simple backup solution. Your data stays on your devices only.';

  @override
  String get noPracticeSessions => 'No practice sessions yet';

  @override
  String get startPracticingToSeeHistory =>
      'Start practicing to see your history here';

  @override
  String get importKnownCharacters => 'Import Known Characters';

  @override
  String get import => 'Import';

  @override
  String get characterMarkedAsLearned => '1 character marked as learned';

  @override
  String charactersMarkedAsLearned(Object count) {
    return '$count characters marked as learned';
  }

  @override
  String get searchByPinyin => 'Search by pinyin, Chinese, or English...';

  @override
  String get showLearnedOnly => 'Show learned only';

  @override
  String get enterPinyinToSearch => 'Enter pinyin to search';

  @override
  String get examples => 'Examples:';

  @override
  String get pinyinExample => 'Pinyin: \"shang\" → 上, 伤, 尚';

  @override
  String get chineseExample => 'Chinese: \"上\" → above/on';

  @override
  String get englishExample => 'English: \"water\" → 水, 江, 河';

  @override
  String get writingModeAutoDesc => 'Strokes convert to font after drawing';

  @override
  String get writingModeHandwritingDesc =>
      'Handwriting with automatic accuracy checking';

  @override
  String get writingModeTrueHandwritingDesc =>
      'Draw and self-assess, best for memory';

  @override
  String get handwriting => 'Handwriting';

  @override
  String get trueHandwriting => 'True Handwriting';

  @override
  String get name => 'Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get targetCharacters => 'Target Characters';

  @override
  String exampleNumber(String number) {
    return 'e.g., $number';
  }

  @override
  String get dailyReviewTarget => 'Daily Review Target';

  @override
  String get characterSetName => 'Character Set Name';

  @override
  String get enterNameForSet => 'Enter a name for this set';

  @override
  String get chineseText => 'Chinese Text';

  @override
  String get pasteOrTypeChineseText => 'Paste or type Chinese text here...';

  @override
  String get enterDefinition => 'Enter definition...';

  @override
  String get exampleMyPracticeSet => 'e.g., My Practice Set';

  @override
  String get exampleCharactersOrWords => 'e.g., 我，你，他 or 你好世界';

  @override
  String get exampleMyVocabulary => 'e.g., My Vocabulary';

  @override
  String get optional => 'Optional';

  @override
  String get newFolder => 'New Folder';

  @override
  String get pleaseEnterFolderName => 'Please enter a folder name';

  @override
  String get coverCharacter => 'Cover Character';

  @override
  String get selectCoverCharacter => 'Select a character to represent this set';

  @override
  String get charactersOrWords => 'Characters/Words';

  @override
  String get useCommasForWords => 'Use commas for words.';

  @override
  String get allChineseCharactersExtracted =>
      'All Chinese characters will be extracted';

  @override
  String characterCount(int count) {
    return '$count characters';
  }

  @override
  String get enterAllCharactersYouKnow =>
      'Enter all characters you already know:';

  @override
  String get exampleChineseCharacters => '你好世界学习中文...';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get settingsHeader => 'SETTINGS';

  @override
  String get supportHeader => 'SUPPORT';

  @override
  String get tapToEditProfile => 'Tap to edit profile';

  @override
  String get user => 'User';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get swap => 'Swap';

  @override
  String pixelsValue(String value) {
    return '$value pixels';
  }

  @override
  String get strokeOrderData => 'Stroke order data and character decomposition';

  @override
  String get dictionaryData => 'Chinese-English dictionary data';

  @override
  String get characterInfoData => 'Character information and radical data';

  @override
  String get viewOnGitHub => 'View on GitHub';

  @override
  String get visitMDBG => 'Visit MDBG';

  @override
  String get visitDiscordServer =>
      'Contribute by reporting/fixing bugs or developing features here';

  @override
  String get learnMore => 'Learn More';

  @override
  String get openSource => 'Open Source';

  @override
  String get openSourceDescription =>
      'Zishu is built with Flutter and uses various open-source libraries. We are grateful to all the contributors who make these resources available.';

  @override
  String get copyrightShaunak => 'Copyright (c) 2016 Shaunak Kishore';

  @override
  String get licensedLGPL => 'Licensed under LGPL-3.0';

  @override
  String get copyrightMDBG => 'Copyright (c) 2024 MDBG';

  @override
  String get licensedCCBY => 'Licensed under CC BY-SA 4.0';

  @override
  String get copyrightUnicode => 'Copyright (c) 1991-2024 Unicode, Inc.';

  @override
  String get licensedUnicode => 'Licensed under the Unicode License Agreement';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get addPhotos => 'Add Photos';

  @override
  String get importFromPhoto => 'Import from Photo';

  @override
  String get removeAll => 'Remove All';

  @override
  String get scanVocabulary => 'Scan Vocabulary';

  @override
  String get processingImages => 'Processing Images';

  @override
  String get extractingCharacters => 'Extracting Characters';

  @override
  String get mayTakeMoment => 'May take a moment';

  @override
  String get ocrProcessing => 'OCR Processing';

  @override
  String get downloadingModel => 'Downloading Model';

  @override
  String get importText => 'Import Text';

  @override
  String get pasteCharactersYouKnow => 'Paste characters you know';

  @override
  String get importFromCSV => 'Import from CSV/TSV';

  @override
  String get uploadCSVFile => 'Upload .csv or .tsv file';

  @override
  String get importFromCSVOrText => 'Import from CSV or text files';

  @override
  String get importCSVDescription =>
      'Import Chinese characters from a CSV or TSV file.';

  @override
  String get fileFormat => 'File format:';

  @override
  String get firstColumnChineseChars =>
      '• First column should contain Chinese characters';

  @override
  String get canIncludeWordsOrChars =>
      '• Can include words or individual characters';

  @override
  String get otherColumnsIgnored => '• Other columns will be ignored';

  @override
  String get supportedFormatsCSV => 'Supported formats: .csv, .tsv';

  @override
  String get selectFile => 'Select File';

  @override
  String get tipPasteFromOtherSources =>
      'Tip: You can paste characters from other sources.';

  @override
  String get setDailyReviewGoal => 'Set Daily Review Goal';

  @override
  String get setDailyReviewDescription =>
      'Set how many characters you want to review/practice each day.';

  @override
  String get appearance => 'Appearance';

  @override
  String get dataExportedSuccessfully => 'Data exported successfully';

  @override
  String get pleasePasteDataToImport => 'Please paste data to import';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get permanentlyDeleteAllData => 'Permanently delete all your data';

  @override
  String get deleteAllDataWarning =>
      'This will delete all your learned characters, practice history, custom sets, and all other data. This action cannot be undone!';

  @override
  String get resetAllData => 'Reset All Data';

  @override
  String get streakSettings => 'Streak Settings';

  @override
  String learnCharsToMaintainStreak(int goal) {
    return 'Learn $goal new characters today to maintain your streak';
  }

  @override
  String get basedOnProgressGoal => 'Based on your progress goal';

  @override
  String get close => 'Close';

  @override
  String get noStatisticsYet => 'No statistics yet';

  @override
  String get practiceToSeeErrorRates =>
      'Practice characters to see your error rates';

  @override
  String get days => 'days';

  @override
  String get exportedDataTapToCopy => 'Exported Data (tap to copy):';

  @override
  String get confirmImport => 'Confirm Import';

  @override
  String foundCharactersToImport(int count) {
    return 'Found $count unique characters to import. Continue?';
  }

  @override
  String get groups => 'Groups';

  @override
  String hskLevelVocabulary(String level) {
    return 'HSK Level $level vocabulary';
  }

  @override
  String groupNumber(int number) {
    return 'Group $number';
  }

  @override
  String itemsCount(int count) {
    return '($count items)';
  }

  @override
  String setGroups(String setName) {
    return '$setName - Groups';
  }

  @override
  String supergroupNumber(int number) {
    return 'Supergroup $number';
  }

  @override
  String get backToSupergroups => '← Back to Supergroups';

  @override
  String get hideGroups => 'Hide Groups';

  @override
  String get hideSupergroups => 'Hide Supergroups';

  @override
  String get showSupergroups => 'Show Supergroups';

  @override
  String get learningMode => 'Learning Mode';

  @override
  String get practiceAll => 'Practice All';

  @override
  String get setLearned => 'Set Learned!';

  @override
  String get noGroupsNeeded => 'No groups needed';

  @override
  String setGroupNumber(String setName, int number) {
    return '$setName - Group $number';
  }

  @override
  String get changeProfilePicture => 'Change Profile Picture';

  @override
  String get loading => 'Loading...';

  @override
  String get chooseFromFiles => 'Choose from Files';

  @override
  String get enterNameToUseInitials => 'Enter name to use initials';

  @override
  String useInitials(String initial) {
    return 'Use Initials ($initial)';
  }

  @override
  String get imageSelected => 'Image selected';

  @override
  String get noImageSelected => 'No image selected';

  @override
  String get submit => 'Submit';

  @override
  String get dataImportedSuccessfully => 'Data imported successfully';

  @override
  String get invalidDataFormat => 'Invalid data format';

  @override
  String get failedToImportData => 'Failed to import data';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get confirmReset => 'Confirm Reset';

  @override
  String get confirmResetQuestion =>
      'Are you absolutely sure you want to reset all data?';

  @override
  String get thisWillPermanentlyDelete => 'This will permanently delete:';

  @override
  String get allLearnedCharactersAndWords =>
      '• All learned characters and words';

  @override
  String get allPracticeHistoryAndStats =>
      '• All practice history and statistics';

  @override
  String get allCustomCharacterSets => '• All custom character sets';

  @override
  String get allFoldersAndOrganization => '• All folders and organization';

  @override
  String get allSettingsAndPreferences => '• All settings and preferences';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone!';

  @override
  String get yesDeleteEverything => 'Yes, Delete Everything';

  @override
  String get allDataHasBeenReset => 'All data has been reset';

  @override
  String get showGroupsButton => 'Show Groups';

  @override
  String get groupsButton => 'Groups';

  @override
  String get chooseHintColor => 'Choose Hint Color';

  @override
  String get hskLevel1Description => 'HSK Level 1 vocabulary';

  @override
  String get hskLevel2Description => 'HSK Level 2 vocabulary (new words only)';

  @override
  String get hskLevel3Description => 'HSK Level 3 vocabulary (new words only)';

  @override
  String get hskLevel4Description => 'HSK Level 4 vocabulary (new words only)';

  @override
  String get hskLevel5Description => 'HSK Level 5 vocabulary (new words only)';

  @override
  String get hskLevel6Description => 'HSK Level 6 vocabulary (new words only)';

  @override
  String get erase => 'Erase';

  @override
  String get showCharacter => 'Show Character';

  @override
  String get hideCharacter => 'Hide Character';

  @override
  String get nextStep => 'Next Step';

  @override
  String get showAll => 'Show All';

  @override
  String get hide => 'Hide';

  @override
  String get createYourOwnPracticeSets =>
      'Create your own practice sets with specific characters or words';

  @override
  String get createYourFirstSet => 'Create Your First Set';

  @override
  String get characterStatistics => 'Character Statistics';

  @override
  String charactersTracked(int count) {
    return '$count characters tracked';
  }

  @override
  String get swipe => 'swipe';

  @override
  String resetStatisticsFor(String character) {
    return 'Reset statistics for $character';
  }

  @override
  String get resetButton => 'Reset';

  @override
  String get setLearningGoal => 'Set Learning Goal';

  @override
  String get targetDate => 'Target Date';

  @override
  String get goalLimitedToMaximum =>
      'Goal limited to 99,999 characters maximum';

  @override
  String get classic => 'Classic';

  @override
  String get invisible => 'Invisible';

  @override
  String get smoothCalligraphyBrush => 'Smooth calligraphy brush';

  @override
  String get noVisualFeedback => 'No visual feedback';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';
}
