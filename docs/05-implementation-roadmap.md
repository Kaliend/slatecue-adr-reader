# Implementation roadmap

## Current status

Implemented:

- native macOS app shell
- import from `XLSX`
- preparation view with actor assignment
- recording workflow with active-actor rules
- quick edit for the selected cue
- responsive display window
- local project packages
- `XLSX` export
- app icon pipeline
- English/Czech language switch

## Recommended next steps

### 1. Autosave and recovery

Highest practical value for real session use.

Goals:

- save the project automatically in the background after important state changes
- recover the latest autosaved state after a crash

### 2. Import validator

Before import, show a lightweight report:

- missing expected columns
- empty `SOURCE` rows
- malformed timecodes
- total rows accepted vs skipped

### 3. Session HUD

Add a compact persistent summary in `Recording`:

- active actor
- remaining eligible cues
- recorded count
- selected character
- selected timecode

### 4. Shortcut polish

Improve operator speed with:

- stricter focus behavior
- more keyboard shortcuts
- quick language-independent recording controls

### 5. Richer export

Consider adding more operational metadata:

- assigned actor
- edited flag
- original text when changed
- recorded timestamps

## Things that should still wait

- `DOCX` import
- audio/video sync
- cloud collaboration
- role-based access control
- heavy editor features
- overbuilt persistence layers
