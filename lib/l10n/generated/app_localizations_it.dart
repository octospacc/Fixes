// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Fixes';

  @override
  String get tabToday => 'Oggi';

  @override
  String get tabHistory => 'Cronologia';

  @override
  String get tabStatistics => 'Statistiche';

  @override
  String get tabItems => 'Articoli';

  @override
  String get tabSettings => 'Impostazioni';

  @override
  String get todayEntries => 'Voci';

  @override
  String get todaySpent => 'Speso';

  @override
  String get todayEmpty => 'Nessuna voce per oggi';

  @override
  String get quickAddEmpty =>
      'Aggiungi articoli dalla scheda Articoli per usare l\'aggiunta rapida.';

  @override
  String get historySearchHint => 'Cerca voci';

  @override
  String get historyEmpty => 'Nessuna voce';

  @override
  String get historyToday => 'Oggi';

  @override
  String get historyYesterday => 'Ieri';

  @override
  String get statsRange7 => '7 giorni';

  @override
  String get statsRange30 => '30 giorni';

  @override
  String get statsRange90 => '90 giorni';

  @override
  String get statsTotalEntries => 'Voci totali';

  @override
  String get statsTotalSpent => 'Totale speso';

  @override
  String get statsDailyCount => 'Conteggio giornaliero';

  @override
  String get statsTopItems => 'Articoli principali';

  @override
  String get statsEmpty => 'Nessun dato';

  @override
  String get itemsEmpty => 'Nessun articolo';

  @override
  String get settingsCurrency => 'Valuta';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Predefinita di sistema';

  @override
  String get settingsDayBoundary => 'Inizio giornata';

  @override
  String get settingsDayStartsAt => 'La giornata inizia alle';

  @override
  String get settingsDayBoundaryHint =>
      'Usato per raggruppare in Oggi e Cronologia. Non modifica i dati salvati.';

  @override
  String get settingsMidnight => 'mezzanotte';

  @override
  String get settingsData => 'Dati';

  @override
  String get settingsExportCsv => 'Esporta CSV';

  @override
  String get settingsImportCsv => 'Importa CSV';

  @override
  String get settingsResetData => 'Ripristina dati';

  @override
  String get settingsResetDataSubtitle =>
      'Elimina tutte le voci e gli articoli';

  @override
  String get settingsAppLabel => 'App';

  @override
  String get settingsVersionLabel => 'Versione';

  @override
  String get settingsAppName => 'Fixes';

  @override
  String get actionSave => 'Salva';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get actionChange => 'Cambia';

  @override
  String get resetTitle => 'Ripristinare i dati?';

  @override
  String get resetBody =>
      'Tutte le voci e gli articoli verranno eliminati definitivamente. Le impostazioni (valuta, inizio giornata) vengono mantenute. Non è possibile annullare.';

  @override
  String get resetConfirm => 'Ripristina';

  @override
  String get entryNew => 'Nuova voce';

  @override
  String get entryEdit => 'Modifica voce';

  @override
  String get entryItemLabel => 'Articolo';

  @override
  String get entryQuantity => 'Quantità';

  @override
  String get entryDate => 'Data';

  @override
  String get entryTime => 'Ora';

  @override
  String get entryIncludeTime => 'Includi ora';

  @override
  String get entryPricePerUnit => 'Prezzo unitario';

  @override
  String get entryNote => 'Nota';

  @override
  String get itemNew => 'Nuovo articolo';

  @override
  String get itemEdit => 'Modifica articolo';

  @override
  String get itemName => 'Nome';

  @override
  String get itemCategory => 'Categoria';

  @override
  String get itemDefaultPrice => 'Prezzo predefinito';

  @override
  String get itemSuggestions => 'Suggerimenti';

  @override
  String get tileUnknownItem => 'Sconosciuto';

  @override
  String get tileAllDay => 'Tutto il giorno';

  @override
  String get tileMore => 'Altro';

  @override
  String get tileUndo => 'Annulla';

  @override
  String tileDeleted(String name) {
    return 'Eliminato \"$name\"';
  }

  @override
  String get fabAddEntry => 'Aggiungi voce';

  @override
  String get fabAddItem => 'Aggiungi articolo';

  @override
  String itemDeleteTitle(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get itemDeleteBodyEmpty =>
      'Questo articolo verrà eliminato definitivamente.';

  @override
  String itemDeleteBodyWithEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voci',
      one: '1 voce',
    );
    return 'Questo articolo e le sue $_temp0 verranno eliminati definitivamente.';
  }

  @override
  String itemDeleted(String name) {
    return 'Eliminato \"$name\"';
  }

  @override
  String get csvImportCancelled => 'Importazione annullata';

  @override
  String get csvImportReadFailed =>
      'Impossibile leggere il contenuto del file. Riprova a selezionare il file.';

  @override
  String get csvImportEmptyFile => 'Il file CSV è vuoto';

  @override
  String get csvImportNoRows => 'Il CSV non contiene righe';

  @override
  String csvImportMissingEntryId(String header) {
    return 'Colonna \"entry_id\" mancante. Intestazione: $header';
  }

  @override
  String get csvImportMissingItemId => 'Colonna \"item_id\" mancante.';

  @override
  String get csvImportMissingDate => 'Colonna \"date\" mancante.';

  @override
  String get csvImportNothingImported =>
      'Nessun elemento importato. Le voci potrebbero essere già presenti.';

  @override
  String csvImportFailed(String error) {
    return 'Importazione non riuscita: $error';
  }

  @override
  String csvImportedEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importate $count voci',
      one: 'Importata 1 voce',
    );
    return '$_temp0';
  }

  @override
  String csvImportedNewItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuovi articoli',
      one: '1 nuovo articolo',
    );
    return '$_temp0';
  }

  @override
  String csvSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saltate',
      one: '1 saltata',
    );
    return '$_temp0';
  }

  @override
  String get presetCoffeeName => 'Caffè';

  @override
  String get presetCoffeeCategory => 'Bevande';

  @override
  String get presetCigaretteName => 'Sigaretta';

  @override
  String get presetCigaretteCategory => 'Fumo';

  @override
  String get presetTeaName => 'Tè';

  @override
  String get presetTeaCategory => 'Bevande';

  @override
  String get presetChipsName => 'Patatine';

  @override
  String get presetChipsCategory => 'Snack';

  @override
  String get presetScratchName => 'Gratta e vinci';

  @override
  String get presetScratchCategory => 'Gioco d\'azzardo';

  @override
  String get presetLunchName => 'Pranzo fuori';

  @override
  String get presetLunchCategory => 'Cibo';

  @override
  String get presetGamingName => 'Sessione di gioco';

  @override
  String get presetGamingCategory => 'Tempo libero';

  @override
  String get dropboxSection => 'Sincronizzazione cloud (Dropbox)';

  @override
  String get dropboxNotConnected => 'Non connesso';

  @override
  String get dropboxConnect => 'Connetti a Dropbox';

  @override
  String get dropboxConnected => 'Connesso a Dropbox';

  @override
  String get dropboxDisconnect => 'Disconnetti';

  @override
  String get dropboxUpload => 'Carica su Dropbox';

  @override
  String get dropboxDownload => 'Scarica da Dropbox';

  @override
  String get dropboxUploadConfirm =>
      'Sostituire il backup su Dropbox con i dati attuali?';

  @override
  String get dropboxDownloadConfirm =>
      'Sostituire i dati locali con il backup da Dropbox? Le modifiche locali andranno perse.';

  @override
  String get dropboxUploaded => 'Backup caricato su Dropbox';

  @override
  String get dropboxDownloaded => 'Backup scaricato da Dropbox';

  @override
  String get dropboxNoBackup => 'Nessun backup trovato su Dropbox';

  @override
  String get dropboxAuthTitle => 'Connetti a Dropbox';

  @override
  String get dropboxAuthInstructions =>
      '1. Apri la pagina di autorizzazione\n2. Approva l\'app\n3. Copia il codice dall\'URL\n4. Incollalo qui sotto';

  @override
  String get dropboxAuthOpen => 'Apri pagina di autorizzazione';

  @override
  String get dropboxAuthCode => 'Codice di autorizzazione';

  @override
  String get dropboxAuthPaste => 'Incolla il codice dall\'URL';

  @override
  String get dropboxAuthComplete => 'Completa connessione';

  @override
  String dropboxAuthError(String error) {
    return 'Impossibile connettersi: $error';
  }

  @override
  String dropboxUploadError(String error) {
    return 'Caricamento non riuscito: $error';
  }

  @override
  String dropboxDownloadError(String error) {
    return 'Download non riuscito: $error';
  }

  @override
  String get dropboxAllSynced => 'Tutte le modifiche sincronizzate';

  @override
  String get dropboxUnsynced => 'Modifiche locali non ancora sincronizzate';

  @override
  String get dropboxNeverSynced => 'Mai sincronizzato';

  @override
  String dropboxLastSynced(String date) {
    return 'Ultima sincronizzazione: $date';
  }
}
