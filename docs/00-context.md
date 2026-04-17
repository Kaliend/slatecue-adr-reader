# Context and decisions

## Problem the app solves

SlateCue is a narrow ADR and dubbing tool for one operator: the director who controls the line flow for actors during a recording session.

The primary workflow is:

- import a cue sheet from `XLSX`
- assign actors to characters
- move through cues in recording order
- optionally edit the current line live
- mark cues as recorded
- project the active line to a second display

This is not a general teleprompter, DAW, studio management system, or multi-user cloud product.

## Operating constraints

- platform: `macOS`
- UI stack: native `SwiftUI`, with small `AppKit` bridges where macOS dialogs make sense
- deployment model: `offline only`
- user count: one person
- source of truth for `v1`: `XLSX`
- no server, sync, accounts, or permissions

## Product decisions fixed for `v1`

- `XLSX` is the only import format
- the importer reads only `SOURCE`, `IN-TIMECODE`, and `DIALOGUE`
- empty cues are valid and must be preserved
- the character name is derived from `SOURCE`
- each character can be assigned to one actor
- the project is saved locally as a `.slatecue` package
- status export is `XLSX` only
- recorded progress is counted at the project level, not per day or session

## What the app actually does today

- opens a `Control` window and a synchronized `Display` window over the same in-memory project
- calculates cue count, word count, `/8` estimate, recorded count, remaining count, and percentage in `Preparation`
- keeps the full visible cue list in `Recording`
- marks the active actor's cues without filtering the list away
- changes navigation and recording rules when an active actor is selected
- supports quick-editing of the selected cue while keeping the original text for instant restore
- updates the display only after an edit is saved
- shows the current cue plus configurable context before and after it
- lets the operator hide the frame part of timecodes in the UI without changing stored data
- highlights cues that belong to the active actor in the display
- supports an app-wide English/Czech language switch

## Recording rules that are intentionally enforced

When no active actor is selected:

- cues can be selected normally
- `Enter` does not record anything
- the UI shows an explicit hint about the missing actor selection

When an active actor is selected:

- only that actor's cues are marked, not filtered
- `Up` and `Down` navigate only between that actor's marked cues
- `Enter` can record only cues that belong to that actor
- if a foreign cue or already recorded cue is selected, `Enter` jumps to the next eligible cue for the active actor
- if no eligible cue remains, recording is blocked and the UI explains why

## Editing rules that are intentionally enforced

- only the currently selected cue can be edited
- edit mode opens via `Edit / E` or double-click
- selection and filters do not change while editing
- `Enter` saves the edit
- `Esc` discards the draft
- the display updates only after save, never on each keystroke
- the cue keeps the original imported dialogue for quick revert

## Sample source patterns that shaped the importer

The importer was designed around real dubbing cue sheet patterns.

Important import implications:

- `SOURCE` may include numeric prefixes such as `61CHARACTER`
- the model must keep both `rawSource` and the normalized character
- `Dialogue List` may contain empty or reaction-like rows
- an empty `DIALOGUE` value is valid and must not be treated as an error

## Things the app deliberately does not do

- `DOCX` import
- audio playback
- waveform or video synchronization
- cloud sync
- user accounts or roles
- multi-variant dialogue history
- bulk edit or rich text editing
- live draft preview on the display while typing
- multi-day session management

## Architectural bias

The product is intentionally small and narrow. That is why the current architecture favors:

- a single central `AppModel`
- a document package over a database
- two windows over one shared in-memory state
- workflow speed and reliability over generality
