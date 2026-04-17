# User guide

## What SlateCue is

SlateCue is a desktop app for ADR and dubbing cue control.
It runs locally on `macOS` and works with one project at a time.

## Typical workflow

1. import an `XLSX`
2. assign actors to characters in `Preparation`
3. open the `Display` window
4. choose the active actor in `Recording`
5. move through cues
6. edit a line if needed
7. mark cues as recorded
8. save the project as `.slatecue`
9. export status to `XLSX` at the end

## Start screen

The welcome screen has three actions:

- `Import XLSX…`
- `Open Project…`
- `Load Demo`

## Import a new project

Use `Import XLSX…`.

The app:

- reads the `Dialogue List` sheet
- extracts `SOURCE`, `IN-TIMECODE`, and `DIALOGUE`
- creates cues
- creates characters
- selects the first cue

## Preparation

At the top you can type a new actor name and press `Add`.

In the summary table you can:

- assign an actor to each character
- see cue count
- see word count
- see the `/8` estimate
- see how many cues are already recorded
- see how many remain

## Recording

This is the main working view.

### Filters and toggles

- `Active actor`
- `Character`
- `Only unrecorded`
- `Hide TC frames`
- `Display +/- N`

### What `Active actor` does

Selecting an actor:

- does not filter the other cues away
- only marks the cues that belong to that actor
- changes navigation
- changes recording rules

### What `Character` does

This filter actually narrows the visible cue list to one character.

### What `Only unrecorded` does

It hides cues that are already marked as recorded.

### What `Hide TC frames` does

It shortens `HH:MM:SS:FF` to `HH:MM:SS` in the UI.
Saved and exported data remain unchanged.

### What `Display +/- N` does

It sets how many cues before and after the current cue are shown in the display window.
The value is saved into the project.

## Recording controls

### Selecting a cue

- click a row to select a cue
- `Up` moves to the previous navigable cue
- `Down` moves to the next navigable cue

With an active actor selected:

- `Up/Down` move only between that actor's marked cues

### Marking a cue as recorded

- `Enter` triggers `Record / Enter`

Rules:

- while editing, `Enter` saves the edit instead
- without an active actor, the cue is not recorded
- with an active actor, only that actor's cues can be recorded
- after recording, the app jumps to the next eligible cue
- if the current cue belongs to another actor or is already recorded, `Enter` skips it

### Reverting a cue state

- `Revert` changes `recorded -> idle`

## Quick edit

Use:

- `Edit / E`
- or double-click on a cue

You will see:

- the selected cue details
- the original text
- an input field for the edited text

Controls:

- `Enter` saves the edit
- `Esc` cancels the draft
- `Restore original text` resets the cue back to the imported line

Rules:

- navigation and recording controls are blocked while editing
- filters and toggles are blocked until the edit is saved or cancelled
- the display updates only after save
- edited cues show an `edited` badge

## Display window

Open it with the `Display` button.

It shows:

- the current cue
- the configured number of previous cues
- the configured number of next cues
- character name
- timecode

With an active actor selected:

- that actor's cues are highlighted
- the other cues stay neutral

The display uses responsive sizing and fills the available vertical space as much as possible.

## Save and open

### Save

Use:

- `Save`
- or `Save Project As…`

New projects are saved as `.slatecue`.

### Open

Use `Open Project…`.

The app restores:

- actor assignments
- cue statuses
- saved cue edits
- filters
- selected cue
- hidden-frame setting
- display context count

## Export

Use `Export`.

The result is an `XLSX` file with two sheets:

- `Cue Status`
- `Character Summary`

## Settings

Open `Settings` from the app menu to switch the UI language between:

- English
- Czech

The setting affects the app UI, dialogs, hints, and demo project content.

## Recommended live session flow

1. assign actors in `Preparation`
2. open `Display`
3. select one active actor in `Recording`
4. keep the full cue list visible
5. move only through that actor's marked cues
6. if a line must change, press `E`, save the edit, and continue
7. confirm each recorded cue with `Enter`
8. switch to the next actor when finished
9. save the project
