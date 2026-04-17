# Troubleshooting

## Import fails with a `Dialogue List` error

Cause:

- the workbook does not contain a sheet named `Dialogue List`

What to check:

- the sheet name
- that the source is really an `XLSX`
- that the workbook is not a custom export with different naming

## Import appears frozen

Current versions import on a background task, so the UI should remain responsive.

If it still feels stuck, check:

- whether the source workbook is very large
- whether the workbook structure is malformed
- whether the app has shown an error alert behind another window

## `Enter` does not record anything

Most common reasons:

- no `Active actor` is selected
- no unrecorded cue remains for the active actor
- the current cue belongs to a different actor, so `Enter` only jumps

## Arrow keys skip other cues

This is expected when an active actor is selected.

Behavior:

- navigation moves only between that actor's marked cues

If you want normal list navigation again:

- clear the `Active actor` selection

## The display shows `(empty cue)`

That is not necessarily an error.

It means the current cue has an empty `DIALOGUE` value and the importer preserved it intentionally.

## The display text does not update while typing

This is intentional.

SlateCue updates the display only after a quick edit is saved.
Draft text is not pushed live to the projection window.

## The language does not change

Check:

- `Settings` was used to switch between English and Czech
- the app window is still open and active

The UI should refresh immediately after the language change.

## A saved project will not open

Check:

- that the package contains `manifest.json`
- that the package was not manually edited or partially copied

The loader can still open older `.ctecka` packages as long as the directory contents are intact.
