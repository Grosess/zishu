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
