import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('it')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixes'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get tabStatistics;

  /// No description provided for @tabItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get tabItems;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @todayEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get todayEntries;

  /// No description provided for @todaySpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get todaySpent;

  /// No description provided for @todayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet today'**
  String get todayEmpty;

  /// No description provided for @quickAddEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add items from the Items tab to use quick add.'**
  String get quickAddEmpty;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search entries, categories, notes'**
  String get historySearchHint;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get historyEmpty;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get historyYesterday;

  /// No description provided for @statsRange7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get statsRange7;

  /// No description provided for @statsRange30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get statsRange30;

  /// No description provided for @statsRange90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get statsRange90;

  /// No description provided for @statsTotalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total entries'**
  String get statsTotalEntries;

  /// No description provided for @statsTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get statsTotalSpent;

  /// No description provided for @statsDailyCount.
  ///
  /// In en, this message translates to:
  /// **'Daily count'**
  String get statsDailyCount;

  /// No description provided for @statsTopItems.
  ///
  /// In en, this message translates to:
  /// **'Top items'**
  String get statsTopItems;

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get statsEmpty;

  /// No description provided for @itemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get itemsEmpty;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsDayBoundary.
  ///
  /// In en, this message translates to:
  /// **'Day boundary'**
  String get settingsDayBoundary;

  /// No description provided for @settingsDayStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Day starts at'**
  String get settingsDayStartsAt;

  /// No description provided for @settingsDayBoundaryHint.
  ///
  /// In en, this message translates to:
  /// **'Used for grouping in Today and History. Storage is unaffected.'**
  String get settingsDayBoundaryHint;

  /// No description provided for @settingsMidnight.
  ///
  /// In en, this message translates to:
  /// **'midnight'**
  String get settingsMidnight;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get settingsExportCsv;

  /// No description provided for @settingsImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get settingsImportCsv;

  /// No description provided for @settingsResetData.
  ///
  /// In en, this message translates to:
  /// **'Reset data'**
  String get settingsResetData;

  /// No description provided for @settingsResetDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all entries and items'**
  String get settingsResetDataSubtitle;

  /// No description provided for @settingsAppLabel.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppLabel;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersionLabel;

  /// No description provided for @settingsAppName.
  ///
  /// In en, this message translates to:
  /// **'Fixes'**
  String get settingsAppName;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset data?'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'All entries and items will be permanently deleted. Settings (currency, day boundary) are kept. This cannot be undone.'**
  String get resetBody;

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetConfirm;

  /// No description provided for @entryNew.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get entryNew;

  /// No description provided for @entryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get entryEdit;

  /// No description provided for @entryItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get entryItemLabel;

  /// No description provided for @entryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get entryQuantity;

  /// No description provided for @entryDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get entryDate;

  /// No description provided for @entryTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get entryTime;

  /// No description provided for @entryIncludeTime.
  ///
  /// In en, this message translates to:
  /// **'Include time'**
  String get entryIncludeTime;

  /// No description provided for @entryPricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price per unit'**
  String get entryPricePerUnit;

  /// No description provided for @entryNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get entryNote;

  /// No description provided for @itemNew.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get itemNew;

  /// No description provided for @itemEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get itemEdit;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get itemName;

  /// No description provided for @itemCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get itemCategory;

  /// No description provided for @itemDefaultPrice.
  ///
  /// In en, this message translates to:
  /// **'Default price'**
  String get itemDefaultPrice;

  /// No description provided for @itemSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get itemSuggestions;

  /// No description provided for @tileUnknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get tileUnknownItem;

  /// No description provided for @tileAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get tileAllDay;

  /// No description provided for @tileMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tileMore;

  /// No description provided for @tileUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get tileUndo;

  /// No description provided for @tileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String tileDeleted(String name);

  /// No description provided for @fabAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get fabAddEntry;

  /// No description provided for @fabAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get fabAddItem;

  /// No description provided for @itemDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String itemDeleteTitle(String name);

  /// No description provided for @itemDeleteBodyEmpty.
  ///
  /// In en, this message translates to:
  /// **'This item will be permanently removed.'**
  String get itemDeleteBodyEmpty;

  /// No description provided for @itemDeleteBodyWithEntries.
  ///
  /// In en, this message translates to:
  /// **'This item and its {count, plural, =1{1 entry} other{{count} entries}} will be permanently removed.'**
  String itemDeleteBodyWithEntries(int count);

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String itemDeleted(String name);

  /// No description provided for @csvImportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Import cancelled'**
  String get csvImportCancelled;

  /// No description provided for @csvImportReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file contents. Try picking the file again.'**
  String get csvImportReadFailed;

  /// No description provided for @csvImportEmptyFile.
  ///
  /// In en, this message translates to:
  /// **'CSV file is empty'**
  String get csvImportEmptyFile;

  /// No description provided for @csvImportNoRows.
  ///
  /// In en, this message translates to:
  /// **'CSV has no rows'**
  String get csvImportNoRows;

  /// No description provided for @csvImportMissingEntryId.
  ///
  /// In en, this message translates to:
  /// **'Missing \"entry_id\" column. Header was: {header}'**
  String csvImportMissingEntryId(String header);

  /// No description provided for @csvImportMissingItemId.
  ///
  /// In en, this message translates to:
  /// **'Missing \"item_id\" column.'**
  String get csvImportMissingItemId;

  /// No description provided for @csvImportMissingDate.
  ///
  /// In en, this message translates to:
  /// **'Missing \"date\" column.'**
  String get csvImportMissingDate;

  /// No description provided for @csvImportNothingImported.
  ///
  /// In en, this message translates to:
  /// **'Nothing imported. All entries may already be present.'**
  String get csvImportNothingImported;

  /// No description provided for @csvImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String csvImportFailed(String error);

  /// No description provided for @csvImportedEntries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 entry} other{Imported {count} entries}}'**
  String csvImportedEntries(int count);

  /// No description provided for @csvImportedNewItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new item} other{{count} new items}}'**
  String csvImportedNewItems(int count);

  /// No description provided for @csvSkippedRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 skipped} other{{count} skipped}}'**
  String csvSkippedRows(int count);

  /// No description provided for @presetCoffeeName.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get presetCoffeeName;

  /// No description provided for @presetCoffeeCategory.
  ///
  /// In en, this message translates to:
  /// **'Drink'**
  String get presetCoffeeCategory;

  /// No description provided for @presetCigaretteName.
  ///
  /// In en, this message translates to:
  /// **'Cigarette'**
  String get presetCigaretteName;

  /// No description provided for @presetCigaretteCategory.
  ///
  /// In en, this message translates to:
  /// **'Smoke'**
  String get presetCigaretteCategory;

  /// No description provided for @presetTeaName.
  ///
  /// In en, this message translates to:
  /// **'Tea'**
  String get presetTeaName;

  /// No description provided for @presetTeaCategory.
  ///
  /// In en, this message translates to:
  /// **'Drink'**
  String get presetTeaCategory;

  /// No description provided for @presetChipsName.
  ///
  /// In en, this message translates to:
  /// **'Chips'**
  String get presetChipsName;

  /// No description provided for @presetChipsCategory.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get presetChipsCategory;

  /// No description provided for @presetScratchName.
  ///
  /// In en, this message translates to:
  /// **'Scratch card'**
  String get presetScratchName;

  /// No description provided for @presetScratchCategory.
  ///
  /// In en, this message translates to:
  /// **'Gambling'**
  String get presetScratchCategory;

  /// No description provided for @presetLunchName.
  ///
  /// In en, this message translates to:
  /// **'Lunch out'**
  String get presetLunchName;

  /// No description provided for @presetLunchCategory.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get presetLunchCategory;

  /// No description provided for @presetGamingName.
  ///
  /// In en, this message translates to:
  /// **'Gaming session'**
  String get presetGamingName;

  /// No description provided for @presetGamingCategory.
  ///
  /// In en, this message translates to:
  /// **'Leisure'**
  String get presetGamingCategory;

  /// No description provided for @dropboxSection.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync (Dropbox)'**
  String get dropboxSection;

  /// No description provided for @dropboxNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get dropboxNotConnected;

  /// No description provided for @dropboxConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect to Dropbox'**
  String get dropboxConnect;

  /// No description provided for @dropboxConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Dropbox'**
  String get dropboxConnected;

  /// No description provided for @dropboxDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get dropboxDisconnect;

  /// No description provided for @dropboxUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload to Dropbox'**
  String get dropboxUpload;

  /// No description provided for @dropboxDownload.
  ///
  /// In en, this message translates to:
  /// **'Download from Dropbox'**
  String get dropboxDownload;

  /// No description provided for @dropboxUploadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace the Dropbox backup with your current data?'**
  String get dropboxUploadConfirm;

  /// No description provided for @dropboxDownloadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace your local data with the Dropbox backup? Local changes will be lost.'**
  String get dropboxDownloadConfirm;

  /// No description provided for @dropboxUploaded.
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded to Dropbox'**
  String get dropboxUploaded;

  /// No description provided for @dropboxDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Backup downloaded from Dropbox'**
  String get dropboxDownloaded;

  /// No description provided for @dropboxNoBackup.
  ///
  /// In en, this message translates to:
  /// **'No backup found on Dropbox'**
  String get dropboxNoBackup;

  /// No description provided for @dropboxAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Dropbox'**
  String get dropboxAuthTitle;

  /// No description provided for @dropboxAuthInstructions.
  ///
  /// In en, this message translates to:
  /// **'1. Open the authorization page\n2. Approve the app\n3. Copy the code from the URL\n4. Paste it below'**
  String get dropboxAuthInstructions;

  /// No description provided for @dropboxAuthOpen.
  ///
  /// In en, this message translates to:
  /// **'Open authorization page'**
  String get dropboxAuthOpen;

  /// No description provided for @dropboxAuthCode.
  ///
  /// In en, this message translates to:
  /// **'Authorization code'**
  String get dropboxAuthCode;

  /// No description provided for @dropboxAuthPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste the code from the URL'**
  String get dropboxAuthPaste;

  /// No description provided for @dropboxAuthComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete connection'**
  String get dropboxAuthComplete;

  /// No description provided for @dropboxAuthError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect: {error}'**
  String dropboxAuthError(String error);

  /// No description provided for @dropboxUploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String dropboxUploadError(String error);

  /// No description provided for @dropboxDownloadError.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String dropboxDownloadError(String error);

  /// No description provided for @dropboxAllSynced.
  ///
  /// In en, this message translates to:
  /// **'All changes synced'**
  String get dropboxAllSynced;

  /// No description provided for @dropboxUnsynced.
  ///
  /// In en, this message translates to:
  /// **'Local changes not yet synced'**
  String get dropboxUnsynced;

  /// No description provided for @dropboxNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get dropboxNeverSynced;

  /// No description provided for @dropboxLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {date}'**
  String dropboxLastSynced(String date);

  /// No description provided for @historyFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get historyFilterTitle;

  /// No description provided for @historyFilterDateSection.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get historyFilterDateSection;

  /// No description provided for @historyFilterAnyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get historyFilterAnyDate;

  /// No description provided for @historyFilterSpecificDay.
  ///
  /// In en, this message translates to:
  /// **'Specific day'**
  String get historyFilterSpecificDay;

  /// No description provided for @historyFilterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get historyFilterDateRange;

  /// No description provided for @historyFilterTimeOfDaySection.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get historyFilterTimeOfDaySection;

  /// No description provided for @historyFilterTimeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get historyFilterTimeFrom;

  /// No description provided for @historyFilterTimeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get historyFilterTimeTo;

  /// No description provided for @historyFilterChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get historyFilterChange;

  /// No description provided for @historyFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get historyFilterClearAll;

  /// No description provided for @historyFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get historyFilterApply;

  /// No description provided for @historyFilterNoResults.
  ///
  /// In en, this message translates to:
  /// **'No entries match the current filters'**
  String get historyFilterNoResults;
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
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
