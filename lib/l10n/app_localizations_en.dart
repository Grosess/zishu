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
}
