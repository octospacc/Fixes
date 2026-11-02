# Fixes

A small, local-first consumption tracker for iOS, iPadOS, macOS, Android, and the web.

Fixes records everyday countable things — coffee, cigarettes, tea, chips, scratch cards, lunch out, gaming sessions — with optional prices and a few useful statistics. The interface is Material 3 throughout, using standard lists, forms, controls, and system typography. There is no account, no server, and no third-party service.

<p align="center">
  <img src="screenshots/today.png" width="270" alt="Today tab with quick add and today's entries">
  <img src="screenshots/statistics.png" width="270" alt="Statistics tab with summary and charts">
  <img src="screenshots/items.png" width="270" alt="Items list">
</p>

## Features

- **Quick add** — tap an item at the top of Today to log one right now.
- **Manual entries** — choose an item, quantity, date, optional time, optional price, and note.
- **Editing and deleting** — tap a row to edit; delete from the **⋮** menu with undo for entries and a confirmation for items.
- **Simple item management** — name, free-form category, and optional default price. Each category gets an icon from a broad built-in map (Coffee, Tea, Drink, Food, Snack, Smoke, Gambling, Gaming, Leisure, Gym, Health, Travel, Work, Study, Home, and many more), with aliases so `Smoking` and `Smoke` draw the same icon while the label stays as typed. Starter suggestions are available in the item editor and are localized.
- **Statistics** — 7-, 30-, and 90-day windows with totals, a daily bar chart, and top items.
- **Custom day boundary** — start the day at any hour (default midnight) to group late-night entries with the correct date. Purely a display boundary; the stored timestamps are unchanged.
- **Configurable currency** — EUR by default, with USD, GBP, JPY, CHF, and CNY available.
- **Localization** — English and Italian, switchable in Settings. Item names, categories, and notes are user data and never translated.
- **Data portability** — export the entire history to CSV, or import an existing CSV. Imports are idempotent by entry id and create missing items from the CSV when needed.
- **Reset data** — clears all entries and items, keeping settings.
- **Native everywhere** — one Flutter codebase for mobile, desktop, and web.

## More screens

<p align="center">
  <img src="screenshots/history.png" width="240" alt="History">
  <img src="screenshots/entry-editor.png" width="240" alt="Entry editor">
  <img src="screenshots/item-editor.png" width="240" alt="Item editor">
</p>

<p align="center">
  <img src="screenshots/dark-mode.png" width="240" alt="Dark mode">
  <img src="screenshots/statistics-wide.png" width="520" alt="Statistics on a wide layout">
</p>

## Requirements

- Flutter 3.22 or newer (Dart 3.4+)
- Targets: iOS 17+, iPadOS 17+, macOS 14+, Android 8+, and modern browsers
- No platform SDKs beyond what `flutter create` generates

## Run

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run on a target:
   ```bash
   flutter run -d macos      # or: -d chrome, -d ios, -d android
   ```

The app starts with an empty ledger. Add starter items or your own items from the **Items** tab. The **Today** tab shows a hint until at least one item exists.

### Signing

Nothing special is required. The project runs with default Flutter signing on every platform. If you later add platform-specific capabilities, use the standard Flutter documentation for each one.

## Data & storage

Fixes is intentionally local-first. There is no account, no sync, and no remote backend.

- **Storage** — the entire dataset is two JSON lists (`items` and `entries`) serialized into `shared_preferences`. On native platforms this maps to `NSUserDefaults` / `SharedPreferences` / `NSUserDefaults` again; on the web it maps to `localStorage`.
- **Size** — comfortably holds tens of thousands of entries. If you ever approach the browser's ~5 MB `localStorage` ceiling, the entire data layer is one file (`lib/data/store.dart`) and can be swapped for Sembast or SQLite without touching the UI.
- **Backup** — Settings → **Export CSV** produces a plain-text file with every entry and its item metadata. Keep it somewhere safe; it is the only portable backup.
- **Reset** — Settings → **Reset data** clears entries and items but preserves currency, language, and day boundary. There is no undo.

## Localization

The app ships with English and Italian.

- UI strings live in `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb`.
- Selecting **System default** in Settings follows the device/browser locale.
- Adding a new language means adding one `.arb` file, running `flutter pub get` (the localization code is regenerated automatically), and adding the language to the dropdown in `settings_view.dart`. No other code changes are needed.
- Item names, categories, and notes are user data and are never translated. The starter presets are localized at pick time, so an Italian user picking "Caffè" stores `Caffè` with category `Bevande`.

## CSV format

Exported headers:

```
entry_id, item_id, item_name, category, default_price, quantity,
date, has_time, price_per_unit, note
```

- `date` is ISO 8601. Epoch-seconds values are also accepted on import for compatibility with exports from older builds.
- `default_price` is blank when the item has no default. `price_per_unit` is blank when the entry was logged without a price.
- Import is **idempotent** — rows whose `entry_id` already exists are skipped. Rows referencing unknown items create those items from `item_name`, `category`, and `default_price`.
- UTF-8, comma- or semicolon-delimited. The importer auto-detects the delimiter and strips a UTF-8 BOM if present.

## Project structure

```text
lib/
  main.dart
  app.dart                       MaterialApp, locale wiring
  l10n/
    app_en.arb                   English strings
    app_it.arb                   Italian strings
    generated/                   Auto-generated AppLocalizations
  data/
    models.dart                  Item, Entry, starter presets
    store.dart                   JSON persistence + logical day helpers
    stats_engine.dart            7/30/90-day aggregation
    money.dart                   Currency formatting
    category_icons.dart          Category → icon map with aliases
    csv_manager.dart             Import/export
  ui/
    root_shell.dart              Tab bar + FAB
    today/                       Quick add, today's entries
    history/                     Searchable day-grouped history
    stats/                       Range picker, chart, top items
    items/                       Item list + editor
    entries/                     Entry tile + editor
    settings/                    Currency, language, day boundary, data, reset
```

## Implementation notes

- **Material 3 on every platform.** No Cupertino widgets, no custom theme layer. Text sizes and colors come from the default Material 3 typography, which stays legible on every platform.
- **Persistence is two JSON strings.** `Store` (a `ChangeNotifier`) writes `items` and `entries` to `shared_preferences`. Every view listens with `ListenableBuilder`, so edits propagate instantly without streams or watchers.
- **The logical day is a display concept only.** `store.logicalDay(DateTime)` and `store.logicalDayRange(DateTime)` shift timestamps by `-dayStartHour` before taking the calendar date. Entry storage is unaffected: the raw timestamp is what gets exported.
- **Price is a snapshot on the entry.** Changing an item's default price never rewrites past entries. Every tile shows the entry's `price_per_unit × quantity` when `price_per_unit` is set, and shows nothing when it isn't.
- **Category names are free-form.** The icon map in `category_icons.dart` resolves aliases (`smoke` / `smoking` / `sigaretta` → one icon) but never changes what the user typed. An unrecognized category gets a neutral tag icon.
- **Imports are additive.** Re-importing the same CSV is a no-op. Entries are keyed by `entry_id`; items are keyed by `item_id`.

## Scope

Fixes intentionally omits cloud sync, user accounts, custom category icons, per-item colors, multiple ledgers, widgets, and notifications. It is a focused personal ledger that works offline and stays out of the way.
