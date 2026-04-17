# SlateCue

Offline macOS app for ADR and dubbing cue reading.

SlateCue is a native `SwiftUI` desktop app for a single dubbing director who needs to import cue sheets from `XLSX`, assign actors to characters, run a fast recording workflow, project text in a dedicated display window, edit lines live during a session, save progress locally, and export status back to `XLSX`.

## Current capabilities

- import `XLSX` from the `Dialogue List` sheet
- read only `SOURCE`, `IN-TIMECODE`, and `DIALOGUE`
- preserve empty cues
- normalize characters from `SOURCE` while keeping the original `rawSource`
- assign actors to characters in `Preparation`
- show all visible cues in `Recording` while only marking the active actor's cues
- limit `Up/Down` and `Enter` behavior to the active actor's cues
- mark cues as recorded and jump to the next eligible cue
- quick-edit the selected cue and restore the original line
- open a separate `Display` window with configurable context before and after the current cue
- keep the display responsive and fill the available vertical space
- highlight active-actor cues in the display
- optionally hide timecode frames in the UI
- save and reopen local `.slatecue` projects
- export `Cue Status` and `Character Summary` to `XLSX`
- switch the UI language in `Settings` between English and Czech

## Operator quick start

1. Launch the app.
2. On the welcome screen choose `Import XLSX…`, `Open Project…`, or `Load Demo`.
3. In `Preparation`, add actors and assign them to characters.
4. Open the `Display` window.
5. Switch to `Recording`.
6. Select the active actor.
7. Navigate with arrow keys or mouse.
8. Press `Enter` to mark the current cue as recorded.
9. Use `Edit / E` whenever a line must be changed live.
10. Save the project as `.slatecue` and export status when needed.

Detailed operator guidance is in [docs/06-user-guide.md](docs/06-user-guide.md).

## Developer quick start

Requirements:

- `macOS`
- `Xcode`
- `xcodegen`

Generate the Xcode project:

```sh
xcodegen generate
```

Build the debug app:

```sh
xcodebuild -project SlateCue.xcodeproj -scheme SlateCue -configuration Debug -derivedDataPath ./.derived-data build
```

Open the built app bundle:

```sh
open -n ./.derived-data/Build/Products/Debug/SlateCue.app
```

Run the one-shot build-and-launch script:

```sh
./run_as_app_bundle.sh
```

Regenerate app icon assets:

```sh
./scripts/build_app_icon.sh
```

More implementation notes are in [docs/07-development-guide.md](docs/07-development-guide.md).

## Documentation

- [Context and product decisions](docs/00-context.md)
- [Product spec](docs/01-product-spec.md)
- [Architecture](docs/02-architecture.md)
- [Data model and persistence](docs/03-data-model.md)
- [Import and export](docs/04-import-export.md)
- [Implementation roadmap](docs/05-implementation-roadmap.md)
- [User guide](docs/06-user-guide.md)
- [Development guide](docs/07-development-guide.md)
- [Troubleshooting](docs/08-troubleshooting.md)

## Repository layout

```text
App/
Domain/
Features/
Services/
UI/
Resources/
design/
docs/
scripts/
project.yml
run_as_app_bundle.sh
```

Key files:

- `App/AppModel.swift`: central app state and recording logic
- `App/LocalizationController.swift`: app-wide language selection
- `Features/Preparation/PreparationView.swift`: actor assignment and preparation summary
- `Features/Recording/RecordingView.swift`: cue list, quick edit, and recording workflow
- `Features/Display/DisplayWindowView.swift`: projection window
- `Services/XLSXDialogueImporter.swift`: `XLSX` import
- `Services/XLSXProjectExporter.swift`: `XLSX` export
- `Services/ProjectPackageStore.swift`: save/load `.slatecue` packages
- `scripts/build_app_icon.swift`: icon asset generation

## Current limits

- `DOCX` import is not implemented
- the app is `offline only`
- there is no audio playback, waveform, video sync, or cloud sync
- there are no automated tests yet
- export is intentionally utilitarian rather than a full spreadsheet writer
