# Data model and persistence

## Project package

SlateCue saves projects as a local `.slatecue` package.

Current layout:

```text
MyProject.slatecue/
  manifest.json
  audit.ndjson
  source/
    original.xlsx
  exports/
```

The `exports/` directory is currently created for structure consistency, even though it is not heavily used yet.

## `DubProject`

`DubProject` is the top-level persistent model.

Key fields:

- `name`
- `sourceFileName`
- `selectedCueID`
- `activeActorFilterID`
- `activeCharacterFilterID`
- `showOnlyUnrecorded`
- `hideTimecodeFrames`
- `displayContextCount`
- `actors`
- `characters`
- `cues`

Important behavior:

- `displayContextCount` is clamped to `>= 0`
- characters and cues are sorted deterministically
- custom decoding provides fallbacks for newer fields so older packages remain readable

## `Cue`

Each cue stores:

- `index`
- `rawSource`
- `characterID`
- `inTimecode`
- `dialogue`
- `originalDialogue`
- `wordCount`
- `status`
- `recordedAt`
- `editedAt`

Notes:

- `rawSource` keeps the original `SOURCE` cell
- `dialogue` is the effective line used for display and export
- `originalDialogue` is set only after the first edit, so the imported line can be restored
- `wordCount` is derived from the effective dialogue

## `Character`

Each character stores:

- `name`
- `rawSourceSamples`
- `assignedActorID`

The importer derives `name` from `SOURCE` by removing leading numeric prefixes.

## `Actor`

Each actor stores:

- `displayName`
- `notes`

`notes` exists for future expansion but is not a major `v1` feature.

## `CharacterSummary`

`CharacterSummary` is a computed read model used by `Preparation`.

It contains:

- cue count
- word count
- planned takes estimate
- recorded cue count
- remaining cue count
- recorded ratio
- linked actor when assigned

## `AuditEvent`

Audit events are append-only session metadata.

Current event types:

- `projectImported`
- `actorAssigned`
- `cueSelected`
- `cueEdited`
- `cueEditReverted`
- `cueRecorded`
- `cueUnrecorded`
- `projectSaved`
- `projectExported`

Stored fields:

- `timestamp`
- `type`
- optional `cueID`
- optional `actorID`
- free-form `payload`

The log is intentionally simple and is not meant to be a full version-control history.

## Derived state in `AppModel`

Important non-persistent derived collections:

- `visibleCues`: cues after character and recorded filters
- `navigableCues`: `visibleCues`, or only active-actor cues when actor mode is enabled
- `displayContext`: previous cues, current cue, next cues for the display
- `characterSummaries`: computed preparation metrics

## Compatibility notes

- new packages save as `.slatecue`
- existing `.ctecka` packages are still openable because the loader reads the directory content rather than relying on the extension alone
