# Architecture

## High-level shape

SlateCue is a single-target macOS app with one shared in-memory project state.

The app uses:

- `SwiftUI` for all screens
- a small amount of `AppKit` for file panels and app icon control
- one `AppModel` as the central state container
- service objects for import, export, shell execution, and package persistence

## Main layers

### App

- `App/SlateCueApp.swift`
- `App/AppModel.swift`
- `App/LocalizationController.swift`
- `App/SettingsView.swift`

Responsibilities:

- scene setup
- command menu wiring
- language state
- global project workflow orchestration

### Domain

- `DubProject`
- `Cue`
- `Character`
- `Actor`
- `AuditEvent`
- `CharacterSummary`

Responsibilities:

- persistent data
- recording state
- summary state

### Features

- `ProjectBrowser/WelcomeView`
- `Preparation/PreparationView`
- `Recording/RecordingView`
- `Display/DisplayWindowView`

Responsibilities:

- render the workflow
- bind UI actions back to `AppModel`

### Services

- `XLSXDialogueImporter`
- `XLSXProjectExporter`
- `ProjectPackageStore`
- `ShellCommand`

Responsibilities:

- read source data
- write exported status
- save/load package contents
- execute system tools such as `unzip`

## Shared-state model

Both the `Control` and `Display` windows are driven by the same `AppModel`.

That gives the app:

- immediate synchronization
- no inter-window messaging layer
- simpler reasoning about selection, edits, and recording state

## Localization model

Localization is intentionally lightweight.

- `LocalizationController` stores the selected `AppLanguage`
- the selection is persisted in `UserDefaults`
- UI strings are resolved through `AppStrings`
- the app defaults to English and can switch to Czech in `Settings`

The design is app-controlled rather than system-locale-controlled because the operator explicitly requested a manual language switch.

## Core workflows

### Import

1. The user chooses an `XLSX` file.
2. `AppModel.importXLSX(from:)` runs the importer on a detached task.
3. `XLSXDialogueImporter` locates `Dialogue List`.
4. It reads `SOURCE`, `IN-TIMECODE`, and `DIALOGUE`.
5. It normalizes characters from `SOURCE`.
6. It builds a `DubProject`.
7. `AppModel` publishes the project to the UI.

Import runs off the main thread so the UI stays responsive.

### Recording

1. The user selects an active actor and a cue.
2. `AppModel.visibleCues` drives the full list.
3. `AppModel.navigableCues` narrows navigation to marked cues when an actor is active.
4. `markSelectedRecordedAndAdvance()` records only eligible cues.
5. The selected cue changes.
6. `DisplayWindowView` redraws from the updated context.

### Quick edit

1. The user opens edit mode on the selected cue.
2. `AppModel` stores `editingCueID` and `cueEditDraft`.
3. The list is effectively frozen while editing.
4. Save updates `Cue.dialogue`, `Cue.wordCount`, and edit metadata.
5. Revert clears `originalDialogue` and `editedAt`.
6. The display redraws only after the save path completes.

### Save/load

1. `ProjectPackageStore` writes `manifest.json`, `audit.ndjson`, and optional source workbook copy.
2. Load reverses the same package layout.
3. Unknown future fields are tolerated through custom decoding fallback in `DubProject`.

## Why there is no database

The current product does not need one.

Reasons:

- one user
- one local machine
- one open project at a time
- explicit save points are acceptable
- package files are easier to inspect, share, and back up

## Why there is no generic localization framework

The app is still small enough that a custom translation table is simpler than introducing a larger localization subsystem.

That keeps:

- the English/Czech switch explicit
- string lookups easy to audit
- user-facing wording close to the workflow code
