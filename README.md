# Fixes

A small, native consumption tracker for iPhone, iPad, and Mac.

Fixes records everyday countable things — coffee, cigarettes, tea, chips, scratch cards, lunch out, gaming sessions — with optional prices and a few useful statistics. The interface uses standard SwiftUI lists, forms, controls, and system typography.

<p align="center">
  <img src="Screenshots/today.png" width="270" alt="Today tab with quick add and today's entries">
  <img src="Screenshots/statistics.png" width="270" alt="Statistics tab with summary and charts">
  <img src="Screenshots/items.png" width="270" alt="Items list">
</p>

## Features

- **Quick add** — tap an item at the top of Today to log one right now.
- **Manual entries** — choose an item, quantity, date, optional time, optional price, and note.
- **Editing and deleting** — tap a row to edit; swipe or use the context menu to delete.
- **Simple item management** — name, category, and optional default price. Starter suggestions are available in the item editor.
- **Statistics** — 7-, 30-, and 90-day windows with totals, daily counts, a spending chart, and top items.
- **Data portability** — export your entire history to a standardized CSV file, or seamlessly import existing data.
- **iCloud sync** — automatic synchronization through the user's private CloudKit database. There is no Fixes account.
- **Native everywhere** — one SwiftUI codebase for iPhone, iPad, and Mac, using system light and dark appearance.

## More screens

<p align="center">
  <img src="Screenshots/history.png" width="240" alt="History">
  <img src="Screenshots/entry-editor.png" width="240" alt="Entry editor">
  <img src="Screenshots/item-editor.png" width="240" alt="Item editor">
</p>

<p align="center">
  <img src="Screenshots/dark-mode.png" width="240" alt="Dark mode">
  <img src="Screenshots/statistics-ipad.png" width="520" alt="Statistics on iPad">
</p>

## Requirements

- Xcode 16 or newer
- iOS / iPadOS 17.0+
- macOS 14.0+
- No third-party dependencies

## Run

1. Open `Fixes.xcodeproj`.
2. Select the **Fixes** scheme and an iPhone, iPad, or Mac destination.
3. Press **Run**.

The app starts with an empty ledger. Add starter items or your own items from the **Items** tab. The **Today** tab has an **Add items** link while the item list is empty.

### Signing

The checked-in project uses manual ad-hoc signing so the iOS simulator can build without a team. Running the Mac target or a physical device with iCloud entitlements requires code signing; select your development team in **Signing & Capabilities** (switch to automatic signing) before running there.

## iCloud sync

Sync uses SwiftData's CloudKit integration with a user's private CloudKit database:

```swift
ModelConfiguration(
    "Fixes",
    schema: schema,
    cloudKitDatabase: .private(CloudSync.containerIdentifier)
)
```

There is no central Fixes account or server. Data belongs to the iCloud account already signed in on the user's devices, and is private to that user.

### Enable sync for your developer account

1. In Xcode, open the **Fixes** target → **Signing & Capabilities**, select your Apple development team, and enable **iCloud** with **CloudKit**.
2. Use the existing container `iCloud.org.eu.octt.Fixes` (or similar), or create/select your own. If you choose another container, update it in both places:
* `Fixes.entitlements`
* `Support/CloudSync.swift`


3. Add the **Push Notifications** capability if Xcode does not add it automatically. Background remote notifications are already declared in `Info.plist`.
4. Run the app on two devices signed into the same iCloud account.
5. For production, open CloudKit Console and deploy the development schema to production.

Sync is handled by SwiftData automatically. Deletion, creation, and edits are eventual — devices receive changes when iCloud delivers them, not instantly.

If the CloudKit-backed container cannot be opened, Fixes falls back to the same local store. An unsigned build can run locally but cannot synchronize; **Settings → iCloud** shows the current account state.

## Tests

* `StatsEngineTests` — totals, window boundaries, item ranking, prices, continuous daily buckets.
* `MoneyTests` — decimal separators, grouping separators, currency symbols, quantity × price.
* `PersistenceTests` — SwiftData save, price snapshot, and cascade delete.

Run tests in Xcode with **Product → Test** (⌘U) on an iOS simulator.

## Debug sample data

Debug builds support launch arguments for screenshots and exploration:

* `-demoData` — seeds a deterministic 35-day history and starter items once.
* `-startTab today|history|statistics|items|settings` — opens a specific tab.
* `-openAddEntry` — opens the new-entry form.
* `-openNewItem` — opens the new-item form.

Set them under **Product → Scheme → Edit Scheme → Run → Arguments**.

## Project structure

```text
Fixes.xcodeproj
Fixes/
  App/                      App entry point, CloudKit container, root navigation
  Models/                   SwiftData models, starter presets, stats engine, CSV manager
  Views/
    Today/                  Quick add, daily summary, today's entries
    History/                Searchable day-grouped history
    Stats/                  Range summary and charts
    Entries/                Entry row and entry form
    Items/                  Item list and item form
    Settings/               Currency, sync status, data management, version
  Support/                  Money/date helpers, CloudKit container constant
  Assets.xcassets/          App icon
  Info.plist
  Fixes.entitlements
FixesTests/
Screenshots/
```

## Implementation notes

* **Standard system UI.** Lists, forms, pickers, steppers, date pickers, toggles, sheets, search, alerts, and Charts use system styles. There is no custom theme or branding layer.
* **CloudKit-compatible models.** No unique constraints, every stored property has a default, and all relationships are optional with an inverse. This is required by SwiftData's CloudKit integration.
* **Price snapshots.** The per-unit price is stored on each entry, so later changes to an item's default price do not rewrite history.
* **Local fallback uses the same store.** If the CloudKit store cannot be opened, the app opens the same configuration with `cloudKitDatabase: .none`, keeping the app usable and keeping the existing local data.
* **Optional time.** Entries store a `hasTime` flag. With time off, the date is normalized to the start of the day and shown as “All day.”
* **Idempotent Imports.** CSV imports rely on Entry IDs and Name matching to prevent duplicate data generation if a user imports the same file twice.

## Scope

Fixes intentionally omits custom icons, per-item colors, multiple ledgers, widgets, and user-facing notifications. It is a focused personal ledger.
