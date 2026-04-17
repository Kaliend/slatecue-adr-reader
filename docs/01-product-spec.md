# Product spec

## Goal

Build a native macOS app that lets a dubbing director:

- prepare a project from `XLSX`
- assign actors to characters
- run a fast line-by-line recording workflow
- project the active line on a separate display
- adjust dialogue live during a session
- save and reopen progress locally
- export the current status to `XLSX`

## Primary user

- one dubbing director
- one workstation
- one active project at a time

## Core input

The app imports one `XLSX` workbook and reads the `Dialogue List` sheet.

Required columns:

- `SOURCE`
- `IN-TIMECODE`
- `DIALOGUE`

## Windows

### Control window

The main operator window contains:

- project import/open/save/export actions
- navigation between `Preparation` and `Recording`
- the complete cue workflow

### Display window

The projection window is read-only and synchronized with the selected cue.

It shows:

- current cue
- configurable cue context before and after
- character name
- timecode

It must remain readable on different window sizes and keep the current cue visually dominant.

## Preparation

Preparation must allow the operator to:

- create actors
- assign one actor to each character
- see per-character summary metrics

Displayed metrics:

- cue count
- word count
- planned takes estimate `ceil(words / 8)`
- recorded cue count
- remaining cue count
- recorded percentage

## Recording

Recording is the main operational mode.

The cue list always shows all visible cues unless another explicit filter removes them.

Controls:

- active actor selector
- character filter
- unrecorded-only toggle
- hide timecode frames toggle
- display context count stepper
- previous / record / revert / next / edit actions

## Active actor behavior

Selecting an active actor must:

- mark that actor's cues
- keep the full visible list on screen
- restrict `Up` and `Down` to that actor's marked cues
- restrict `Enter` recording to that actor's cues only

When no actor is selected:

- cues can be selected
- `Enter` must not record anything

When the current cue does not belong to the active actor:

- `Enter` must jump to the next eligible cue for that actor

## Quick edit

The selected cue can be edited through a compact, low-friction editor.

Required behavior:

- open via `Edit / E` or double-click
- show original text and editable text
- `Enter` saves
- `Esc` cancels
- `Restore original text` resets the cue to the imported line
- the display updates only after save
- the cue shows an edited indicator in the list

## Display behavior

The display window must:

- show the current cue in the center
- show a configurable number of preceding and following cues
- keep a stable horizontal slot for timecode
- highlight cues for the active actor
- resize text and card layout responsively
- use the available vertical space efficiently

## Settings

The app includes a `Settings` window with an app-wide language picker.

Supported languages:

- English
- Czech

The language setting must affect:

- app commands
- window labels
- view labels and hints
- save/open dialog labels
- user-facing error strings
- demo project content generated from the app

## Save and export

### Save

The app saves a local `.slatecue` package that contains:

- project manifest
- audit log
- optional source workbook copy

Older `.ctecka` packages should remain openable because package loading is directory-based.

### Export

The exporter writes one `XLSX` file with:

- `Cue Status`
- `Character Summary`

## Acceptance checklist for the current `v1`

- import works on the reference workbook structure
- empty cues survive import, display, save, and export
- actor assignment works
- `Enter` only records cues for the selected actor
- `Up/Down` only navigate that actor's cues when an active actor is selected
- quick edit works without breaking the recording flow
- the display follows the selected cue and shows configurable context
- the app can switch between English and Czech from `Settings`
- the app builds as a native macOS bundle with icon and local save/export support
