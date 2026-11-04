// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fixes';

  @override
  String get tabToday => 'Today';

  @override
  String get tabHistory => 'History';

  @override
  String get tabStatistics => 'Statistics';

  @override
  String get tabItems => 'Items';

  @override
  String get tabSettings => 'Settings';

  @override
  String get todayEntries => 'Entries';

  @override
  String get todaySpent => 'Spent';

  @override
  String get todayEmpty => 'No entries yet today';

  @override
  String get quickAddEmpty => 'Add items from the Items tab to use quick add.';

  @override
  String get historySearchHint => 'Search entries, categories, notes';

  @override
  String get historyEmpty => 'No entries';

  @override
  String get historyToday => 'Today';

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String get statsRange7 => '7 days';

  @override
  String get statsRange30 => '30 days';

  @override
  String get statsRange90 => '90 days';

  @override
  String get statsTotalEntries => 'Total entries';

  @override
  String get statsTotalSpent => 'Total spent';

  @override
  String get statsDailyCount => 'Daily count';

  @override
  String get statsTopItems => 'Top items';

  @override
  String get statsEmpty => 'No data yet';

  @override
  String get itemsEmpty => 'No items yet';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsDayBoundary => 'Day boundary';

  @override
  String get settingsDayStartsAt => 'Day starts at';

  @override
  String get settingsDayBoundaryHint =>
      'Used for grouping in Today and History. Storage is unaffected.';

  @override
  String get settingsMidnight => 'midnight';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsExportCsv => 'Export CSV';

  @override
  String get settingsImportCsv => 'Import CSV';

  @override
  String get settingsResetData => 'Reset data';

  @override
  String get settingsResetDataSubtitle => 'Delete all entries and items';

  @override
  String get settingsAppLabel => 'App';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get settingsAppName => 'Fixes';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionChange => 'Change';

  @override
  String get resetTitle => 'Reset data?';

  @override
  String get resetBody =>
      'All entries and items will be permanently deleted. Settings (currency, day boundary) are kept. This cannot be undone.';

  @override
  String get resetConfirm => 'Reset';

  @override
  String get entryNew => 'New entry';

  @override
  String get entryEdit => 'Edit entry';

  @override
  String get entryItemLabel => 'Item';

  @override
  String get entryQuantity => 'Quantity';

  @override
  String get entryDate => 'Date';

  @override
  String get entryTime => 'Time';

  @override
  String get entryIncludeTime => 'Include time';

  @override
  String get entryPricePerUnit => 'Price per unit';

  @override
  String get entryNote => 'Note';

  @override
  String get itemNew => 'New item';

  @override
  String get itemEdit => 'Edit item';

  @override
  String get itemName => 'Name';

  @override
  String get itemCategory => 'Category';

  @override
  String get itemDefaultPrice => 'Default price';

  @override
  String get itemSuggestions => 'Suggestions';

  @override
  String get tileUnknownItem => 'Unknown';

  @override
  String get tileAllDay => 'All day';

  @override
  String get tileMore => 'More';

  @override
  String get tileUndo => 'Undo';

  @override
  String tileDeleted(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get fabAddEntry => 'Add entry';

  @override
  String get fabAddItem => 'Add item';

  @override
  String itemDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get itemDeleteBodyEmpty => 'This item will be permanently removed.';

  @override
  String itemDeleteBodyWithEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return 'This item and its $_temp0 will be permanently removed.';
  }

  @override
  String itemDeleted(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get csvImportCancelled => 'Import cancelled';

  @override
  String get csvImportReadFailed =>
      'Could not read the file contents. Try picking the file again.';

  @override
  String get csvImportEmptyFile => 'CSV file is empty';

  @override
  String get csvImportNoRows => 'CSV has no rows';

  @override
  String csvImportMissingEntryId(String header) {
    return 'Missing \"entry_id\" column. Header was: $header';
  }

  @override
  String get csvImportMissingItemId => 'Missing \"item_id\" column.';

  @override
  String get csvImportMissingDate => 'Missing \"date\" column.';

  @override
  String get csvImportNothingImported =>
      'Nothing imported. All entries may already be present.';

  @override
  String csvImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String csvImportedEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count entries',
      one: 'Imported 1 entry',
    );
    return '$_temp0';
  }

  @override
  String csvImportedNewItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new items',
      one: '1 new item',
    );
    return '$_temp0';
  }

  @override
  String csvSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skipped',
      one: '1 skipped',
    );
    return '$_temp0';
  }

  @override
  String get presetCoffeeName => 'Coffee';

  @override
  String get presetCoffeeCategory => 'Drink';

  @override
  String get presetCigaretteName => 'Cigarette';

  @override
  String get presetCigaretteCategory => 'Smoke';

  @override
  String get presetTeaName => 'Tea';

  @override
  String get presetTeaCategory => 'Drink';

  @override
  String get presetChipsName => 'Chips';

  @override
  String get presetChipsCategory => 'Snack';

  @override
  String get presetScratchName => 'Scratch card';

  @override
  String get presetScratchCategory => 'Gambling';

  @override
  String get presetLunchName => 'Lunch out';

  @override
  String get presetLunchCategory => 'Food';

  @override
  String get presetGamingName => 'Gaming session';

  @override
  String get presetGamingCategory => 'Leisure';

  @override
  String get dropboxSection => 'Cloud Sync (Dropbox)';

  @override
  String get dropboxNotConnected => 'Not connected';

  @override
  String get dropboxConnect => 'Connect to Dropbox';

  @override
  String get dropboxConnected => 'Connected to Dropbox';

  @override
  String get dropboxDisconnect => 'Disconnect';

  @override
  String get dropboxUpload => 'Upload to Dropbox';

  @override
  String get dropboxDownload => 'Download from Dropbox';

  @override
  String get dropboxUploadConfirm =>
      'Replace the Dropbox backup with your current data?';

  @override
  String get dropboxDownloadConfirm =>
      'Replace your local data with the Dropbox backup? Local changes will be lost.';

  @override
  String get dropboxUploaded => 'Backup uploaded to Dropbox';

  @override
  String get dropboxDownloaded => 'Backup downloaded from Dropbox';

  @override
  String get dropboxNoBackup => 'No backup found on Dropbox';

  @override
  String get dropboxAuthTitle => 'Connect to Dropbox';

  @override
  String get dropboxAuthInstructions =>
      '1. Open the authorization page\n2. Approve the app\n3. Copy the code from the URL\n4. Paste it below';

  @override
  String get dropboxAuthOpen => 'Open authorization page';

  @override
  String get dropboxAuthCode => 'Authorization code';

  @override
  String get dropboxAuthPaste => 'Paste the code from the URL';

  @override
  String get dropboxAuthComplete => 'Complete connection';

  @override
  String dropboxAuthError(String error) {
    return 'Could not connect: $error';
  }

  @override
  String dropboxUploadError(String error) {
    return 'Upload failed: $error';
  }

  @override
  String dropboxDownloadError(String error) {
    return 'Download failed: $error';
  }

  @override
  String get dropboxAllSynced => 'All changes synced';

  @override
  String get dropboxUnsynced => 'Local changes not yet synced';

  @override
  String get dropboxNeverSynced => 'Never synced';

  @override
  String dropboxLastUpload(String date) {
    return 'Last upload: $date';
  }

  @override
  String dropboxLastDownload(String date) {
    return 'Last download: $date';
  }

  @override
  String get dropboxAutoSync => 'Automatic sync';

  @override
  String get dropboxAutoSyncHintOn =>
      'Uploads after changes. Downloads on launch, on resume, and every minute while the app is open.';

  @override
  String get dropboxAutoSyncHintOff =>
      'Use the buttons below to sync manually.';

  @override
  String get dropboxSyncNow => 'Sync now';

  @override
  String get dropboxRestore => 'Restore from Dropbox';

  @override
  String get dropboxRestoreConfirm =>
      'Replace your local data with the Dropbox backup? Local changes will be lost.';

  @override
  String get historyFilterTitle => 'Filters';

  @override
  String get historyFilterDateSection => 'Date';

  @override
  String get historyFilterAnyDate => 'Any date';

  @override
  String get historyFilterSpecificDay => 'Specific day';

  @override
  String get historyFilterDateRange => 'Date range';

  @override
  String get historyFilterTimeOfDaySection => 'Time of day';

  @override
  String get historyFilterTimeFrom => 'From';

  @override
  String get historyFilterTimeTo => 'To';

  @override
  String get historyFilterChange => 'Change';

  @override
  String get historyFilterClearAll => 'Clear all';

  @override
  String get historyFilterApply => 'Apply';

  @override
  String get historyFilterNoResults => 'No entries match the current filters';

  @override
  String get historyFilterPriceSection => 'Price per unit';

  @override
  String get historyFilterPriceAny => 'Any price';

  @override
  String get historyFilterPriceHas => 'Has a price';

  @override
  String get historyFilterPriceNo => 'No price';

  @override
  String get historyFilterPriceRange => 'Price range';

  @override
  String get historyFilterPriceMin => 'Min';

  @override
  String get historyFilterPriceMax => 'Max';

  @override
  String get statsTopCategories => 'Top categories';

  @override
  String get statsCurrentStreak => 'days in a row';

  @override
  String statsBestStreak(int count) {
    return 'best: $count';
  }

  @override
  String get statsAveragePerDay => 'avg / day';

  @override
  String statsAverageSpendSubtitle(String amount) {
    return '$amount / day';
  }

  @override
  String get statsLastSeenToday => 'today';

  @override
  String get statsLastSeenYesterday => 'yesterday';

  @override
  String statsLastSeenDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String settingsRepoOpenFailed(String url) {
    return 'Could not open $url';
  }
}
