import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Zishu'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @characterSets.
  ///
  /// In en, this message translates to:
  /// **'Character Sets'**
  String get characterSets;

  /// No description provided for @builtIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtIn;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @editSet.
  ///
  /// In en, this message translates to:
  /// **'Edit Set'**
  String get editSet;

  /// No description provided for @deleteSet.
  ///
  /// In en, this message translates to:
  /// **'Delete Set'**
  String get deleteSet;

  /// No description provided for @renameSet.
  ///
  /// In en, this message translates to:
  /// **'Rename Set'**
  String get renameSet;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChanges;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @markAllAsLearned.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Learned'**
  String get markAllAsLearned;

  /// No description provided for @markAllAsLearnedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to mark all {count} {type} in \"{name}\" as learned?\n\nYou will not be able to undo this action.'**
  String markAllAsLearnedConfirm(int count, String type, String name);

  /// No description provided for @words.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get words;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get cards;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @addItems.
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get addItems;

  /// No description provided for @enterItems.
  ///
  /// In en, this message translates to:
  /// **'Enter items separated by commas, spaces, or new lines'**
  String get enterItems;

  /// No description provided for @exampleItems.
  ///
  /// In en, this message translates to:
  /// **'e.g., 你好, 世界, 中国'**
  String get exampleItems;

  /// No description provided for @setName.
  ///
  /// In en, this message translates to:
  /// **'Set name'**
  String get setName;

  /// No description provided for @enterNewName.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get enterNewName;

  /// No description provided for @createdFrom.
  ///
  /// In en, this message translates to:
  /// **'Created from: {source}'**
  String createdFrom(String source);

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress: {percent}%'**
  String progressLabel(int percent);

  /// No description provided for @noItemsInSet.
  ///
  /// In en, this message translates to:
  /// **'No items in this set'**
  String get noItemsInSet;

  /// No description provided for @cannotSaveEmptySet.
  ///
  /// In en, this message translates to:
  /// **'Cannot save an empty set'**
  String get cannotSaveEmptySet;

  /// No description provided for @deleteSetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deleteSetConfirm(String name);

  /// No description provided for @createNewSet.
  ///
  /// In en, this message translates to:
  /// **'Create New Set'**
  String get createNewSet;

  /// No description provided for @enterCharacters.
  ///
  /// In en, this message translates to:
  /// **'Enter characters or words'**
  String get enterCharacters;

  /// No description provided for @importFromText.
  ///
  /// In en, this message translates to:
  /// **'Import from text'**
  String get importFromText;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @duotone.
  ///
  /// In en, this message translates to:
  /// **'Duotone'**
  String get duotone;

  /// No description provided for @classicFixed.
  ///
  /// In en, this message translates to:
  /// **'Classic (Fixed)'**
  String get classicFixed;

  /// No description provided for @chooseStrokeType.
  ///
  /// In en, this message translates to:
  /// **'Choose Stroke Type'**
  String get chooseStrokeType;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @chineseLanguage.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chineseLanguage;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @duotoneMode.
  ///
  /// In en, this message translates to:
  /// **'Duotone Mode'**
  String get duotoneMode;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purple;

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// No description provided for @pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get pink;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @black.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get black;

  /// No description provided for @white.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get white;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get gridView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @allItemsLearned.
  ///
  /// In en, this message translates to:
  /// **'All items in this set have been learned!'**
  String get allItemsLearned;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon'**
  String get featureComingSoon;

  /// No description provided for @searchSets.
  ///
  /// In en, this message translates to:
  /// **'Search sets...'**
  String get searchSets;

  /// No description provided for @noSetsFound.
  ///
  /// In en, this message translates to:
  /// **'No sets found'**
  String get noSetsFound;

  /// No description provided for @searchAdditionalSets.
  ///
  /// In en, this message translates to:
  /// **'Search additional sets to add...'**
  String get searchAdditionalSets;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Zishu'**
  String get welcomeTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select your preferred language:'**
  String get welcomeMessage;

  /// No description provided for @markedItemsAsLearned.
  ///
  /// In en, this message translates to:
  /// **'Marked {count} items as learned'**
  String markedItemsAsLearned(int count);

  /// No description provided for @deletedSet.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String deletedSet(String name);

  /// No description provided for @changeColor.
  ///
  /// In en, this message translates to:
  /// **'Change Color'**
  String get changeColor;

  /// No description provided for @moveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to Folder'**
  String get moveToFolder;

  /// No description provided for @mergeWithAnotherSet.
  ///
  /// In en, this message translates to:
  /// **'Merge with Another Set'**
  String get mergeWithAnotherSet;

  /// No description provided for @countSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String countSelected(int count);

  /// No description provided for @countItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String countItems(int count);

  /// No description provided for @charactersBy.
  ///
  /// In en, this message translates to:
  /// **'characters by'**
  String get charactersBy;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'{count} per day'**
  String perDay(int count);

  /// No description provided for @there.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get there;

  /// No description provided for @ahead.
  ///
  /// In en, this message translates to:
  /// **'ahead'**
  String get ahead;

  /// No description provided for @behind.
  ///
  /// In en, this message translates to:
  /// **'behind'**
  String get behind;

  /// No description provided for @countAhead.
  ///
  /// In en, this message translates to:
  /// **'{count} ahead'**
  String countAhead(int count);

  /// No description provided for @countBehind.
  ///
  /// In en, this message translates to:
  /// **'{count} behind'**
  String countBehind(int count);

  /// No description provided for @endlessPractice.
  ///
  /// In en, this message translates to:
  /// **'Endless Practice'**
  String get endlessPractice;

  /// No description provided for @practiceAllLearned.
  ///
  /// In en, this message translates to:
  /// **'Practice all {count} learned items'**
  String practiceAllLearned(int count);

  /// No description provided for @searchCharacters.
  ///
  /// In en, this message translates to:
  /// **'Search Characters'**
  String get searchCharacters;

  /// No description provided for @findByPinyin.
  ///
  /// In en, this message translates to:
  /// **'Find by pinyin, Chinese or English'**
  String get findByPinyin;

  /// No description provided for @recentSets.
  ///
  /// In en, this message translates to:
  /// **'Recent Sets'**
  String get recentSets;

  /// No description provided for @noRecentSets.
  ///
  /// In en, this message translates to:
  /// **'No recent practice sets.'**
  String get noRecentSets;

  /// No description provided for @startPracticingSets.
  ///
  /// In en, this message translates to:
  /// **'Start practicing from the Sets tab!'**
  String get startPracticingSets;

  /// No description provided for @sessionSummary.
  ///
  /// In en, this message translates to:
  /// **'Session Summary'**
  String get sessionSummary;

  /// No description provided for @practiceIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Practice Incorrect'**
  String get practiceIncorrect;

  /// No description provided for @createSet.
  ///
  /// In en, this message translates to:
  /// **'Create Set'**
  String get createSet;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @nameYourPracticeSet.
  ///
  /// In en, this message translates to:
  /// **'Name Your Practice Set'**
  String get nameYourPracticeSet;

  /// No description provided for @noLearnedItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No learned items found. Please learn some characters first!'**
  String get noLearnedItemsFound;

  /// No description provided for @couldNotOpenFeedback.
  ///
  /// In en, this message translates to:
  /// **'Could not open feedback form'**
  String get couldNotOpenFeedback;

  /// No description provided for @noValidCharactersFound.
  ///
  /// In en, this message translates to:
  /// **'No valid characters found for practice'**
  String get noValidCharactersFound;

  /// No description provided for @showGroups.
  ///
  /// In en, this message translates to:
  /// **'Show Groups'**
  String get showGroups;

  /// No description provided for @todaysLearn.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Learn'**
  String get todaysLearn;

  /// No description provided for @todaysReview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Review'**
  String get todaysReview;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// No description provided for @cardsStudied.
  ///
  /// In en, this message translates to:
  /// **'Cards Studied'**
  String get cardsStudied;

  /// No description provided for @timeToday.
  ///
  /// In en, this message translates to:
  /// **'Time Today'**
  String get timeToday;

  /// No description provided for @dailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get dailyStreak;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @verbs.
  ///
  /// In en, this message translates to:
  /// **'Verbs'**
  String get verbs;

  /// No description provided for @dailyActivities.
  ///
  /// In en, this message translates to:
  /// **'Daily Activities'**
  String get dailyActivities;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @moreComingSoon.
  ///
  /// In en, this message translates to:
  /// **'More coming soon...'**
  String get moreComingSoon;

  /// No description provided for @andMoreCount.
  ///
  /// In en, this message translates to:
  /// **'... and {count} more'**
  String andMoreCount(int count);

  /// No description provided for @noCustomSets.
  ///
  /// In en, this message translates to:
  /// **'No Custom Sets'**
  String get noCustomSets;

  /// No description provided for @createCustomSet.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Set'**
  String get createCustomSet;

  /// No description provided for @removeFromBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Remove from Built-in'**
  String get removeFromBuiltin;

  /// No description provided for @deleteCustomSet.
  ///
  /// In en, this message translates to:
  /// **'Delete Custom Set'**
  String get deleteCustomSet;

  /// No description provided for @createFolder.
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createFolder;

  /// No description provided for @renameFolder.
  ///
  /// In en, this message translates to:
  /// **'Rename Folder'**
  String get renameFolder;

  /// No description provided for @deleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get deleteFolder;

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Color'**
  String get chooseColor;

  /// No description provided for @mergeSets.
  ///
  /// In en, this message translates to:
  /// **'Merge Sets'**
  String get mergeSets;

  /// No description provided for @confirmMerge.
  ///
  /// In en, this message translates to:
  /// **'Confirm Merge'**
  String get confirmMerge;

  /// No description provided for @noFolder.
  ///
  /// In en, this message translates to:
  /// **'No Folder'**
  String get noFolder;

  /// No description provided for @allItemsLearnedMessage.
  ///
  /// In en, this message translates to:
  /// **'All items in this set have been learned!'**
  String get allItemsLearnedMessage;

  /// No description provided for @noLearnedItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No learned items in this set yet. Use \"Learn\" first!'**
  String get noLearnedItemsMessage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @someItemsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Some items unavailable'**
  String get someItemsUnavailable;

  /// No description provided for @ofGoal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} goal'**
  String ofGoal(Object goal);

  /// No description provided for @setGoalButton.
  ///
  /// In en, this message translates to:
  /// **'Set Goal'**
  String get setGoalButton;

  /// No description provided for @totalCharactersLearned.
  ///
  /// In en, this message translates to:
  /// **'Total Characters Learned'**
  String get totalCharactersLearned;

  /// No description provided for @totalStudyTime.
  ///
  /// In en, this message translates to:
  /// **'Total Study Time'**
  String get totalStudyTime;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String minutesShort(Object count);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String hoursShort(Object count);

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String daysShort(Object count);

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String setsCount(Object count);

  /// No description provided for @setCount.
  ///
  /// In en, this message translates to:
  /// **'{count} set'**
  String setCount(Object count);

  /// No description provided for @searchCharactersHint.
  ///
  /// In en, this message translates to:
  /// **'Search characters...'**
  String get searchCharactersHint;

  /// No description provided for @endless.
  ///
  /// In en, this message translates to:
  /// **'Endless'**
  String get endless;

  /// No description provided for @teal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get teal;

  /// No description provided for @lightPink.
  ///
  /// In en, this message translates to:
  /// **'Light Pink'**
  String get lightPink;

  /// No description provided for @hotPink.
  ///
  /// In en, this message translates to:
  /// **'Hot Pink'**
  String get hotPink;

  /// No description provided for @blueGreen.
  ///
  /// In en, this message translates to:
  /// **'Blue Green'**
  String get blueGreen;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get themeColor;

  /// No description provided for @practiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Practice Settings'**
  String get practiceSettings;

  /// No description provided for @handwritingMode.
  ///
  /// In en, this message translates to:
  /// **'Handwriting Mode'**
  String get handwritingMode;

  /// No description provided for @handwritingModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Draw freely without stroke guidance, then self-assess'**
  String get handwritingModeDesc;

  /// No description provided for @showGrid.
  ///
  /// In en, this message translates to:
  /// **'Show Grid'**
  String get showGrid;

  /// No description provided for @showGridDesc.
  ///
  /// In en, this message translates to:
  /// **'Display grid lines in the practice area'**
  String get showGridDesc;

  /// No description provided for @showGuideByDefault.
  ///
  /// In en, this message translates to:
  /// **'Show Guide by Default'**
  String get showGuideByDefault;

  /// No description provided for @showGuideDesc.
  ///
  /// In en, this message translates to:
  /// **'Show character outline in learning mode'**
  String get showGuideDesc;

  /// No description provided for @strokeWidth.
  ///
  /// In en, this message translates to:
  /// **'Stroke Width'**
  String get strokeWidth;

  /// No description provided for @strokeColor.
  ///
  /// In en, this message translates to:
  /// **'Stroke Color'**
  String get strokeColor;

  /// No description provided for @strokeType.
  ///
  /// In en, this message translates to:
  /// **'Stroke Type'**
  String get strokeType;

  /// No description provided for @strokeAppearance.
  ///
  /// In en, this message translates to:
  /// **'Stroke Appearance'**
  String get strokeAppearance;

  /// No description provided for @autoPronounce.
  ///
  /// In en, this message translates to:
  /// **'Auto-Pronounce Chinese'**
  String get autoPronounce;

  /// No description provided for @autoPronounceDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically speak characters and words'**
  String get autoPronounceDesc;

  /// No description provided for @cardsPerGroup.
  ///
  /// In en, this message translates to:
  /// **'Cards Per Group'**
  String get cardsPerGroup;

  /// No description provided for @cardsPerGroupDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} characters per group'**
  String cardsPerGroupDesc(int count);

  /// No description provided for @attributions.
  ///
  /// In en, this message translates to:
  /// **'Attributions'**
  String get attributions;

  /// No description provided for @attributionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Third-party licenses and credits'**
  String get attributionsDesc;

  /// No description provided for @swapColors.
  ///
  /// In en, this message translates to:
  /// **'Swap Colors'**
  String get swapColors;

  /// No description provided for @swapColorsDesc.
  ///
  /// In en, this message translates to:
  /// **'Swap background and accent colors'**
  String get swapColorsDesc;

  /// No description provided for @hintColor.
  ///
  /// In en, this message translates to:
  /// **'Hint Color'**
  String get hintColor;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @charactersPerDay.
  ///
  /// In en, this message translates to:
  /// **'characters per day'**
  String get charactersPerDay;

  /// No description provided for @dataRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Recovery Notice'**
  String get dataRecoveryTitle;

  /// No description provided for @dataRecoverySuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully recovered {count} sets from backup'**
  String dataRecoverySuccess(int count);

  /// No description provided for @dataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Sets'**
  String get dataLoadError;

  /// No description provided for @dataLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Some sets could not be loaded due to corrupted data. Recovered {recovered} out of {total} sets.'**
  String dataLoadErrorMessage(int recovered, int total);

  /// No description provided for @dataParseError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load custom sets. Data may be corrupted. Attempting recovery from backup...'**
  String get dataParseError;

  /// No description provided for @dataRecoveryFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Recovered data from backup! {count} sets restored.'**
  String dataRecoveryFromBackup(int count);

  /// No description provided for @noBackupAvailable.
  ///
  /// In en, this message translates to:
  /// **'No backup available. Please report this issue if you lost data.'**
  String get noBackupAvailable;

  /// No description provided for @dataSaveWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: Unable to save changes. Please try again or contact support if the problem persists.'**
  String get dataSaveWarning;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String goodEvening(String name);

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String goodMorning(String name);

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String goodAfternoon(String name);

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night, {name}'**
  String goodNight(String name);

  /// No description provided for @keepUpTheGreatWork.
  ///
  /// In en, this message translates to:
  /// **'Keep up the great work!'**
  String get keepUpTheGreatWork;

  /// No description provided for @writingMode.
  ///
  /// In en, this message translates to:
  /// **'Writing Mode'**
  String get writingMode;

  /// No description provided for @writingModeNormal.
  ///
  /// In en, this message translates to:
  /// **'Stroke by Stroke'**
  String get writingModeNormal;

  /// No description provided for @writingModeNormalDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow stroke order with guidance'**
  String get writingModeNormalDesc;

  /// No description provided for @writingModeFree.
  ///
  /// In en, this message translates to:
  /// **'Free Draw'**
  String get writingModeFree;

  /// No description provided for @writingModeFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Draw freely without stroke guidance'**
  String get writingModeFreeDesc;

  /// No description provided for @showStrokeAnimation.
  ///
  /// In en, this message translates to:
  /// **'Show Stroke Animation'**
  String get showStrokeAnimation;

  /// No description provided for @showStrokeAnimationDesc.
  ///
  /// In en, this message translates to:
  /// **'Animate the correct stroke path'**
  String get showStrokeAnimationDesc;

  /// No description provided for @showRadicalAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Show Radical Analysis'**
  String get showRadicalAnalysis;

  /// No description provided for @showRadicalAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'Display character radical breakdown'**
  String get showRadicalAnalysisDesc;

  /// No description provided for @beta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get beta;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedback;

  /// No description provided for @hapticFeedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on interactions'**
  String get hapticFeedbackDesc;

  /// No description provided for @strokeLeniency.
  ///
  /// In en, this message translates to:
  /// **'Stroke Leniency'**
  String get strokeLeniency;

  /// No description provided for @strokeLeniencyDesc.
  ///
  /// In en, this message translates to:
  /// **'How strict stroke validation is'**
  String get strokeLeniencyDesc;

  /// No description provided for @mostMissed.
  ///
  /// In en, this message translates to:
  /// **'Most Missed'**
  String get mostMissed;

  /// No description provided for @errorRate.
  ///
  /// In en, this message translates to:
  /// **'error rate'**
  String get errorRate;

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get wrong;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @attempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get attempts;

  /// No description provided for @dataAndProgress.
  ///
  /// In en, this message translates to:
  /// **'Data & Progress'**
  String get dataAndProgress;

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataBackup;

  /// No description provided for @practiceHistory.
  ///
  /// In en, this message translates to:
  /// **'Practice History'**
  String get practiceHistory;

  /// No description provided for @markAsLearned.
  ///
  /// In en, this message translates to:
  /// **'Mark as Learned'**
  String get markAsLearned;

  /// No description provided for @giveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Give Feedback'**
  String get giveFeedback;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @howToUseZishu.
  ///
  /// In en, this message translates to:
  /// **'How to Use Zishu'**
  String get howToUseZishu;

  /// No description provided for @howToUseZishuTutorial.
  ///
  /// In en, this message translates to:
  /// **'How to Use Zishu Tutorial'**
  String get howToUseZishuTutorial;

  /// No description provided for @enterFolderName.
  ///
  /// In en, this message translates to:
  /// **'Enter folder name'**
  String get enterFolderName;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// No description provided for @second.
  ///
  /// In en, this message translates to:
  /// **'second'**
  String get second;

  /// No description provided for @usingDuotoneForeground.
  ///
  /// In en, this message translates to:
  /// **'Using Duotone Foreground'**
  String get usingDuotoneForeground;

  /// No description provided for @pixels.
  ///
  /// In en, this message translates to:
  /// **'pixels'**
  String get pixels;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @strokesConvertToFont.
  ///
  /// In en, this message translates to:
  /// **'Strokes convert to font after drawing'**
  String get strokesConvertToFont;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @saveProgressToShare.
  ///
  /// In en, this message translates to:
  /// **'Save your progress to share with other devices'**
  String get saveProgressToShare;

  /// No description provided for @exportDataButton.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportDataButton;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @restoreProgress.
  ///
  /// In en, this message translates to:
  /// **'Restore your progress from another device'**
  String get restoreProgress;

  /// No description provided for @pasteExportedData.
  ///
  /// In en, this message translates to:
  /// **'Paste exported data here'**
  String get pasteExportedData;

  /// No description provided for @importDataButton.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importDataButton;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works:'**
  String get howItWorks;

  /// No description provided for @exportDataStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Export your data on one device'**
  String get exportDataStep1;

  /// No description provided for @exportDataStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Copy the exported text'**
  String get exportDataStep2;

  /// No description provided for @exportDataStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Send it to your other device (email, message, etc.)'**
  String get exportDataStep3;

  /// No description provided for @exportDataStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Paste and import on the other device'**
  String get exportDataStep4;

  /// No description provided for @backupNote.
  ///
  /// In en, this message translates to:
  /// **'Note: This is a simple backup solution. Your data stays on your devices only.'**
  String get backupNote;

  /// No description provided for @noPracticeSessions.
  ///
  /// In en, this message translates to:
  /// **'No practice sessions yet'**
  String get noPracticeSessions;

  /// No description provided for @startPracticingToSeeHistory.
  ///
  /// In en, this message translates to:
  /// **'Start practicing to see your history here'**
  String get startPracticingToSeeHistory;

  /// No description provided for @importKnownCharacters.
  ///
  /// In en, this message translates to:
  /// **'Import Known Characters'**
  String get importKnownCharacters;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @characterMarkedAsLearned.
  ///
  /// In en, this message translates to:
  /// **'1 character marked as learned'**
  String get characterMarkedAsLearned;

  /// No description provided for @charactersMarkedAsLearned.
  ///
  /// In en, this message translates to:
  /// **'{count} characters marked as learned'**
  String charactersMarkedAsLearned(Object count);

  /// No description provided for @searchByPinyin.
  ///
  /// In en, this message translates to:
  /// **'Search by pinyin, Chinese, or English...'**
  String get searchByPinyin;

  /// No description provided for @showLearnedOnly.
  ///
  /// In en, this message translates to:
  /// **'Show learned only'**
  String get showLearnedOnly;

  /// No description provided for @enterPinyinToSearch.
  ///
  /// In en, this message translates to:
  /// **'Enter pinyin to search'**
  String get enterPinyinToSearch;

  /// No description provided for @examples.
  ///
  /// In en, this message translates to:
  /// **'Examples:'**
  String get examples;

  /// No description provided for @pinyinExample.
  ///
  /// In en, this message translates to:
  /// **'Pinyin: \"shang\" → 上, 伤, 尚'**
  String get pinyinExample;

  /// No description provided for @chineseExample.
  ///
  /// In en, this message translates to:
  /// **'Chinese: \"上\" → above/on'**
  String get chineseExample;

  /// No description provided for @englishExample.
  ///
  /// In en, this message translates to:
  /// **'English: \"water\" → 水, 江, 河'**
  String get englishExample;

  /// No description provided for @writingModeAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Strokes convert to font after drawing'**
  String get writingModeAutoDesc;

  /// No description provided for @writingModeHandwritingDesc.
  ///
  /// In en, this message translates to:
  /// **'Handwriting with automatic accuracy checking'**
  String get writingModeHandwritingDesc;

  /// No description provided for @writingModeTrueHandwritingDesc.
  ///
  /// In en, this message translates to:
  /// **'Draw and self-assess, best for memory'**
  String get writingModeTrueHandwritingDesc;

  /// No description provided for @handwriting.
  ///
  /// In en, this message translates to:
  /// **'Handwriting'**
  String get handwriting;

  /// No description provided for @trueHandwriting.
  ///
  /// In en, this message translates to:
  /// **'True Handwriting'**
  String get trueHandwriting;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @targetCharacters.
  ///
  /// In en, this message translates to:
  /// **'Target Characters'**
  String get targetCharacters;

  /// No description provided for @exampleNumber.
  ///
  /// In en, this message translates to:
  /// **'e.g., {number}'**
  String exampleNumber(String number);

  /// No description provided for @dailyReviewTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily Review Target'**
  String get dailyReviewTarget;

  /// No description provided for @characterSetName.
  ///
  /// In en, this message translates to:
  /// **'Character Set Name'**
  String get characterSetName;

  /// No description provided for @enterNameForSet.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this set'**
  String get enterNameForSet;

  /// No description provided for @chineseText.
  ///
  /// In en, this message translates to:
  /// **'Chinese Text'**
  String get chineseText;

  /// No description provided for @pasteOrTypeChineseText.
  ///
  /// In en, this message translates to:
  /// **'Paste or type Chinese text here...'**
  String get pasteOrTypeChineseText;

  /// No description provided for @enterDefinition.
  ///
  /// In en, this message translates to:
  /// **'Enter definition...'**
  String get enterDefinition;

  /// No description provided for @exampleMyPracticeSet.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Practice Set'**
  String get exampleMyPracticeSet;

  /// No description provided for @exampleCharactersOrWords.
  ///
  /// In en, this message translates to:
  /// **'e.g., 我，你，他 or 你好世界'**
  String get exampleCharactersOrWords;

  /// No description provided for @exampleMyVocabulary.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Vocabulary'**
  String get exampleMyVocabulary;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @pleaseEnterFolderName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a folder name'**
  String get pleaseEnterFolderName;

  /// No description provided for @coverCharacter.
  ///
  /// In en, this message translates to:
  /// **'Cover Character'**
  String get coverCharacter;

  /// No description provided for @selectCoverCharacter.
  ///
  /// In en, this message translates to:
  /// **'Select a character to represent this set'**
  String get selectCoverCharacter;

  /// No description provided for @charactersOrWords.
  ///
  /// In en, this message translates to:
  /// **'Characters/Words'**
  String get charactersOrWords;

  /// No description provided for @useCommasForWords.
  ///
  /// In en, this message translates to:
  /// **'Use commas for words.'**
  String get useCommasForWords;

  /// No description provided for @allChineseCharactersExtracted.
  ///
  /// In en, this message translates to:
  /// **'All Chinese characters will be extracted'**
  String get allChineseCharactersExtracted;

  /// No description provided for @characterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} characters'**
  String characterCount(int count);

  /// No description provided for @enterAllCharactersYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Enter all characters you already know:'**
  String get enterAllCharactersYouKnow;

  /// No description provided for @exampleChineseCharacters.
  ///
  /// In en, this message translates to:
  /// **'你好世界学习中文...'**
  String get exampleChineseCharacters;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @settingsHeader.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsHeader;

  /// No description provided for @supportHeader.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get supportHeader;

  /// No description provided for @tapToEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit profile'**
  String get tapToEditProfile;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @pixelsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} pixels'**
  String pixelsValue(String value);

  /// No description provided for @strokeOrderData.
  ///
  /// In en, this message translates to:
  /// **'Stroke order data and character decomposition'**
  String get strokeOrderData;

  /// No description provided for @dictionaryData.
  ///
  /// In en, this message translates to:
  /// **'Chinese-English dictionary data'**
  String get dictionaryData;

  /// No description provided for @characterInfoData.
  ///
  /// In en, this message translates to:
  /// **'Character information and radical data'**
  String get characterInfoData;

  /// No description provided for @viewOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get viewOnGitHub;

  /// No description provided for @visitMDBG.
  ///
  /// In en, this message translates to:
  /// **'Visit MDBG'**
  String get visitMDBG;

  /// No description provided for @visitDiscordServer.
  ///
  /// In en, this message translates to:
  /// **'Contribute by reporting/fixing bugs or developing features here'**
  String get visitDiscordServer;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get openSource;

  /// No description provided for @openSourceDescription.
  ///
  /// In en, this message translates to:
  /// **'Zishu is built with Flutter and uses various open-source libraries. We are grateful to all the contributors who make these resources available.'**
  String get openSourceDescription;

  /// No description provided for @copyrightShaunak.
  ///
  /// In en, this message translates to:
  /// **'Copyright (c) 2016 Shaunak Kishore'**
  String get copyrightShaunak;

  /// No description provided for @licensedLGPL.
  ///
  /// In en, this message translates to:
  /// **'Licensed under LGPL-3.0'**
  String get licensedLGPL;

  /// No description provided for @copyrightMDBG.
  ///
  /// In en, this message translates to:
  /// **'Copyright (c) 2024 MDBG'**
  String get copyrightMDBG;

  /// No description provided for @licensedCCBY.
  ///
  /// In en, this message translates to:
  /// **'Licensed under CC BY-SA 4.0'**
  String get licensedCCBY;

  /// No description provided for @copyrightUnicode.
  ///
  /// In en, this message translates to:
  /// **'Copyright (c) 1991-2024 Unicode, Inc.'**
  String get copyrightUnicode;

  /// No description provided for @licensedUnicode.
  ///
  /// In en, this message translates to:
  /// **'Licensed under the Unicode License Agreement'**
  String get licensedUnicode;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @importFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'Import from Photo'**
  String get importFromPhoto;

  /// No description provided for @removeAll.
  ///
  /// In en, this message translates to:
  /// **'Remove All'**
  String get removeAll;

  /// No description provided for @scanVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Scan Vocabulary'**
  String get scanVocabulary;

  /// No description provided for @processingImages.
  ///
  /// In en, this message translates to:
  /// **'Processing Images'**
  String get processingImages;

  /// No description provided for @extractingCharacters.
  ///
  /// In en, this message translates to:
  /// **'Extracting Characters'**
  String get extractingCharacters;

  /// No description provided for @mayTakeMoment.
  ///
  /// In en, this message translates to:
  /// **'May take a moment'**
  String get mayTakeMoment;

  /// No description provided for @ocrProcessing.
  ///
  /// In en, this message translates to:
  /// **'OCR Processing'**
  String get ocrProcessing;

  /// No description provided for @downloadingModel.
  ///
  /// In en, this message translates to:
  /// **'Downloading Model'**
  String get downloadingModel;

  /// No description provided for @importText.
  ///
  /// In en, this message translates to:
  /// **'Import Text'**
  String get importText;

  /// No description provided for @pasteCharactersYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Paste characters you know'**
  String get pasteCharactersYouKnow;

  /// No description provided for @importFromCSV.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV/TSV'**
  String get importFromCSV;

  /// No description provided for @uploadCSVFile.
  ///
  /// In en, this message translates to:
  /// **'Upload .csv or .tsv file'**
  String get uploadCSVFile;

  /// No description provided for @importFromCSVOrText.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV or text files'**
  String get importFromCSVOrText;

  /// No description provided for @importCSVDescription.
  ///
  /// In en, this message translates to:
  /// **'Import Chinese characters from a CSV or TSV file.'**
  String get importCSVDescription;

  /// No description provided for @fileFormat.
  ///
  /// In en, this message translates to:
  /// **'File format:'**
  String get fileFormat;

  /// No description provided for @firstColumnChineseChars.
  ///
  /// In en, this message translates to:
  /// **'• First column should contain Chinese characters'**
  String get firstColumnChineseChars;

  /// No description provided for @canIncludeWordsOrChars.
  ///
  /// In en, this message translates to:
  /// **'• Can include words or individual characters'**
  String get canIncludeWordsOrChars;

  /// No description provided for @otherColumnsIgnored.
  ///
  /// In en, this message translates to:
  /// **'• Other columns will be ignored'**
  String get otherColumnsIgnored;

  /// No description provided for @supportedFormatsCSV.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: .csv, .tsv'**
  String get supportedFormatsCSV;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @tipPasteFromOtherSources.
  ///
  /// In en, this message translates to:
  /// **'Tip: You can paste characters from other sources.'**
  String get tipPasteFromOtherSources;

  /// No description provided for @setDailyReviewGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Daily Review Goal'**
  String get setDailyReviewGoal;

  /// No description provided for @setDailyReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Set how many characters you want to review/practice each day.'**
  String get setDailyReviewDescription;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @dataExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get dataExportedSuccessfully;

  /// No description provided for @pleasePasteDataToImport.
  ///
  /// In en, this message translates to:
  /// **'Please paste data to import'**
  String get pleasePasteDataToImport;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @permanentlyDeleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all your data'**
  String get permanentlyDeleteAllData;

  /// No description provided for @deleteAllDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This will delete all your learned characters, practice history, custom sets, and all other data. This action cannot be undone!'**
  String get deleteAllDataWarning;

  /// No description provided for @resetAllData.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get resetAllData;

  /// No description provided for @streakSettings.
  ///
  /// In en, this message translates to:
  /// **'Streak Settings'**
  String get streakSettings;

  /// No description provided for @learnCharsToMaintainStreak.
  ///
  /// In en, this message translates to:
  /// **'Learn {goal} new characters today to maintain your streak'**
  String learnCharsToMaintainStreak(int goal);

  /// No description provided for @basedOnProgressGoal.
  ///
  /// In en, this message translates to:
  /// **'Based on your progress goal'**
  String get basedOnProgressGoal;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noStatisticsYet.
  ///
  /// In en, this message translates to:
  /// **'No statistics yet'**
  String get noStatisticsYet;

  /// No description provided for @practiceToSeeErrorRates.
  ///
  /// In en, this message translates to:
  /// **'Practice characters to see your error rates'**
  String get practiceToSeeErrorRates;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @exportedDataTapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Exported Data (tap to copy):'**
  String get exportedDataTapToCopy;

  /// No description provided for @confirmImport.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get confirmImport;

  /// No description provided for @foundCharactersToImport.
  ///
  /// In en, this message translates to:
  /// **'Found {count} unique characters to import. Continue?'**
  String foundCharactersToImport(int count);

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @hskLevelVocabulary.
  ///
  /// In en, this message translates to:
  /// **'HSK Level {level} vocabulary'**
  String hskLevelVocabulary(String level);

  /// No description provided for @groupNumber.
  ///
  /// In en, this message translates to:
  /// **'Group {number}'**
  String groupNumber(int number);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'({count} items)'**
  String itemsCount(int count);

  /// No description provided for @setGroups.
  ///
  /// In en, this message translates to:
  /// **'{setName} - Groups'**
  String setGroups(String setName);

  /// No description provided for @supergroupNumber.
  ///
  /// In en, this message translates to:
  /// **'Supergroup {number}'**
  String supergroupNumber(int number);

  /// No description provided for @backToSupergroups.
  ///
  /// In en, this message translates to:
  /// **'← Back to Supergroups'**
  String get backToSupergroups;

  /// No description provided for @hideGroups.
  ///
  /// In en, this message translates to:
  /// **'Hide Groups'**
  String get hideGroups;

  /// No description provided for @hideSupergroups.
  ///
  /// In en, this message translates to:
  /// **'Hide Supergroups'**
  String get hideSupergroups;

  /// No description provided for @showSupergroups.
  ///
  /// In en, this message translates to:
  /// **'Show Supergroups'**
  String get showSupergroups;

  /// No description provided for @learningMode.
  ///
  /// In en, this message translates to:
  /// **'Learning Mode'**
  String get learningMode;

  /// No description provided for @practiceAll.
  ///
  /// In en, this message translates to:
  /// **'Practice All'**
  String get practiceAll;

  /// No description provided for @setLearned.
  ///
  /// In en, this message translates to:
  /// **'Set Learned!'**
  String get setLearned;

  /// No description provided for @noGroupsNeeded.
  ///
  /// In en, this message translates to:
  /// **'No groups needed'**
  String get noGroupsNeeded;

  /// No description provided for @setGroupNumber.
  ///
  /// In en, this message translates to:
  /// **'{setName} - Group {number}'**
  String setGroupNumber(String setName, int number);

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePicture;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @chooseFromFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose from Files'**
  String get chooseFromFiles;

  /// No description provided for @enterNameToUseInitials.
  ///
  /// In en, this message translates to:
  /// **'Enter name to use initials'**
  String get enterNameToUseInitials;

  /// No description provided for @useInitials.
  ///
  /// In en, this message translates to:
  /// **'Use Initials ({initial})'**
  String useInitials(String initial);

  /// No description provided for @imageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get imageSelected;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @dataImportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully'**
  String get dataImportedSuccessfully;

  /// No description provided for @invalidDataFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid data format'**
  String get invalidDataFormat;

  /// No description provided for @failedToImportData.
  ///
  /// In en, this message translates to:
  /// **'Failed to import data'**
  String get failedToImportData;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @confirmReset.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset'**
  String get confirmReset;

  /// No description provided for @confirmResetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to reset all data?'**
  String get confirmResetQuestion;

  /// No description provided for @thisWillPermanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:'**
  String get thisWillPermanentlyDelete;

  /// No description provided for @allLearnedCharactersAndWords.
  ///
  /// In en, this message translates to:
  /// **'• All learned characters and words'**
  String get allLearnedCharactersAndWords;

  /// No description provided for @allPracticeHistoryAndStats.
  ///
  /// In en, this message translates to:
  /// **'• All practice history and statistics'**
  String get allPracticeHistoryAndStats;

  /// No description provided for @allCustomCharacterSets.
  ///
  /// In en, this message translates to:
  /// **'• All custom character sets'**
  String get allCustomCharacterSets;

  /// No description provided for @allFoldersAndOrganization.
  ///
  /// In en, this message translates to:
  /// **'• All folders and organization'**
  String get allFoldersAndOrganization;

  /// No description provided for @allSettingsAndPreferences.
  ///
  /// In en, this message translates to:
  /// **'• All settings and preferences'**
  String get allSettingsAndPreferences;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone!'**
  String get thisActionCannotBeUndone;

  /// No description provided for @yesDeleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete Everything'**
  String get yesDeleteEverything;

  /// No description provided for @allDataHasBeenReset.
  ///
  /// In en, this message translates to:
  /// **'All data has been reset'**
  String get allDataHasBeenReset;

  /// No description provided for @showGroupsButton.
  ///
  /// In en, this message translates to:
  /// **'Show Groups'**
  String get showGroupsButton;

  /// No description provided for @groupsButton.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsButton;

  /// No description provided for @chooseHintColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Hint Color'**
  String get chooseHintColor;

  /// No description provided for @hskLevel1Description.
  ///
  /// In en, this message translates to:
  /// **'HSK Level 1 vocabulary'**
  String get hskLevel1Description;

  /// No description provided for @hskLevel2Description.
  ///
  /// In en, this message translates to:
  /// **'HSK Level 2 vocabulary (new words only)'**
  String get hskLevel2Description;

  /// No description provided for @hskLevel3Description.
  ///
  /// In en, this message translates to:
  /// **'HSK Level 3 vocabulary (new words only)'**
  String get hskLevel3Description;

  /// No description provided for @hskLevel4Description.
  ///
  /// In en, this message translates to:
  /// **'HSK Level 4 vocabulary (new words only)'**
  String get hskLevel4Description;

  /// No description provided for @hskLevel5Description.
  ///
  /// In en, this message translates to:
  /// **'HSK Level 5 vocabulary (new words only)'**
  String get hskLevel5Description;

  /// No description provided for @hskLevel6Description.
  ///
  /// In en, this message translates to:
  /// **'HSK Level 6 vocabulary (new words only)'**
  String get hskLevel6Description;

  /// No description provided for @erase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get erase;

  /// No description provided for @showCharacter.
  ///
  /// In en, this message translates to:
  /// **'Show Character'**
  String get showCharacter;

  /// No description provided for @hideCharacter.
  ///
  /// In en, this message translates to:
  /// **'Hide Character'**
  String get hideCharacter;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @createYourOwnPracticeSets.
  ///
  /// In en, this message translates to:
  /// **'Create your own practice sets with specific characters or words'**
  String get createYourOwnPracticeSets;

  /// No description provided for @createYourFirstSet.
  ///
  /// In en, this message translates to:
  /// **'Create Your First Set'**
  String get createYourFirstSet;

  /// No description provided for @characterStatistics.
  ///
  /// In en, this message translates to:
  /// **'Character Statistics'**
  String get characterStatistics;

  /// No description provided for @charactersTracked.
  ///
  /// In en, this message translates to:
  /// **'{count} characters tracked'**
  String charactersTracked(int count);

  /// No description provided for @swipe.
  ///
  /// In en, this message translates to:
  /// **'swipe'**
  String get swipe;

  /// No description provided for @resetStatisticsFor.
  ///
  /// In en, this message translates to:
  /// **'Reset statistics for {character}'**
  String resetStatisticsFor(String character);

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @setLearningGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Learning Goal'**
  String get setLearningGoal;

  /// No description provided for @targetDate.
  ///
  /// In en, this message translates to:
  /// **'Target Date'**
  String get targetDate;

  /// No description provided for @goalLimitedToMaximum.
  ///
  /// In en, this message translates to:
  /// **'Goal limited to 99,999 characters maximum'**
  String get goalLimitedToMaximum;

  /// No description provided for @classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get classic;

  /// No description provided for @invisible.
  ///
  /// In en, this message translates to:
  /// **'Invisible'**
  String get invisible;

  /// No description provided for @smoothCalligraphyBrush.
  ///
  /// In en, this message translates to:
  /// **'Smooth calligraphy brush'**
  String get smoothCalligraphyBrush;

  /// No description provided for @noVisualFeedback.
  ///
  /// In en, this message translates to:
  /// **'No visual feedback'**
  String get noVisualFeedback;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
