# Development guide

## Requirements

- `macOS`
- `Xcode`
- `xcodegen`

## Generate the Xcode project

```sh
xcodegen generate
```

The generated project file is `SlateCue.xcodeproj`, and the built app product is `SlateCue.app`.

## Build

```sh
xcodebuild -project SlateCue.xcodeproj -scheme SlateCue -configuration Debug -derivedDataPath ./.derived-data build
```

## Run the built app

```sh
open -n ./.derived-data/Build/Products/Debug/SlateCue.app
```

## Convenience script

Use:

```sh
./run_as_app_bundle.sh
```

It will:

- regenerate icon assets when needed
- run `xcodegen generate`
- build the debug bundle
- open `SlateCue.app`

## Icon pipeline

Source:

- `design/AppIcon-source.png`

Generator:

- `scripts/build_app_icon.swift`
- `scripts/build_app_icon.sh`

## Localization

Localization is implemented through:

- `AppLanguage`
- `LocalizationController`
- `AppStrings`

The language switch is stored in `UserDefaults` and exposed through the app-wide settings scene.

## Main files

- `App/AppModel.swift`
- `App/SlateCueApp.swift`
- `App/LocalizationController.swift`
- `Features/Preparation/PreparationView.swift`
- `Features/Recording/RecordingView.swift`
- `Features/Display/DisplayWindowView.swift`
- `Services/XLSXDialogueImporter.swift`
- `Services/XLSXProjectExporter.swift`
- `Services/ProjectPackageStore.swift`

## Important implementation notes

### Import runs off the main thread

`AppModel.importXLSX(from:)` uses a detached task so the UI does not freeze while parsing the workbook.

### Active actor does not filter the whole list

This is intentional.

- `visibleCues` controls what the list shows
- `navigableCues` controls what `Up/Down` and `Enter` operate on

### Display follows saved state, not drafts

The display renders only from the project model.
While quick-edit is open, the draft text stays local until save.

### Package decoding is backward-tolerant

`DubProject` has a custom decoder with fallbacks for newer fields.

That keeps older saved packages readable after incremental feature additions.

## Manual verification checklist

1. import a real workbook
2. load the demo project
3. add an actor
4. assign actors to characters
5. open `Display`
6. select an active actor
7. verify `Up/Down` only move across that actor's cues
8. verify `Enter` only records eligible cues
9. quick-edit a cue, save it, then restore the original line
10. toggle hidden timecode frames
11. change `Display +/- N`
12. switch app language in `Settings`
13. save and reopen a `.slatecue` project
14. export `XLSX`
