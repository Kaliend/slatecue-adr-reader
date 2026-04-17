# Import and export

## Import

## Source format

The importer expects an `XLSX` workbook with a sheet named `Dialogue List`.

Only these columns are used:

- `SOURCE`
- `IN-TIMECODE`
- `DIALOGUE`

Any additional workbook structure is ignored.

## Import behavior

The importer:

- opens the workbook as a zip container
- reads workbook metadata and relationships
- locates the `Dialogue List` worksheet
- resolves shared strings
- parses row values
- normalizes headers
- builds `Character` and `Cue` values

## Character normalization

Character names are derived from `SOURCE` by stripping numeric prefixes.

Example:

- `61CHARACTER` -> `CHARACTER`

The original `SOURCE` text is still kept in `Cue.rawSource`.

## Empty cues

Blank dialogue rows are valid and preserved.

Rules:

- if `SOURCE`, `IN-TIMECODE`, and `DIALOGUE` are all empty, the row is skipped
- if only `DIALOGUE` is empty, the cue is still imported

## Import errors

The current importer reports a small set of explicit user-facing errors:

- missing `Dialogue List` sheet
- unreadable workbook structure
- failed shell command while extracting workbook content

## Export

The exporter writes one `XLSX` file with two worksheets:

- `Cue Status`
- `Character Summary`

## Export contents

`Cue Status` includes the operational state of each cue, including the current effective dialogue.

`Character Summary` includes the per-character rollup shown in the preparation screen.

## Important export rule

The exporter uses the current effective cue text, not only the original imported text.

That means quick edits are reflected in the exported workbook.

## Current limits

- no `DOCX` import
- no schema validator yet
- no rich formatting preservation
- no export back into the original workbook layout
