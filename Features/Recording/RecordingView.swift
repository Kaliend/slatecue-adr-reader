import SwiftUI

struct RecordingView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var localization: LocalizationController
    @FocusState private var isEditFieldFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            filtersBar
            controlsBar
            cueEditBar
            cueHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(appModel.visibleCues) { cue in
                            cueRow(cue)
                                .id(cue.id)
                                .allowsHitTesting(!appModel.isEditingCue)
                                .onTapGesture {
                                    appModel.selectCue(cue.id)
                                }
                                .onTapGesture(count: 2) {
                                    guard !appModel.isEditingCue else { return }
                                    appModel.selectCue(cue.id)
                                    appModel.startEditingSelectedCue()
                                }
                        }
                    }
                    .padding(.bottom, 12)
                }
                .allowsHitTesting(!appModel.isEditingCue)
                .background(
                    KeyboardMonitorView(isEnabled: !appModel.isEditingCue) { event in
                        switch event.keyCode {
                        case 125:
                            appModel.moveSelection(by: 1)
                            return true
                        case 126:
                            appModel.moveSelection(by: -1)
                            return true
                        case 36:
                            appModel.markSelectedRecordedAndAdvance()
                            return true
                        case 14:
                            appModel.startEditingSelectedCue()
                            return true
                        default:
                            return false
                        }
                    }
                )
                .onChange(of: appModel.project?.selectedCueID) { _, cueID in
                    guard let cueID else { return }
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(cueID, anchor: .center)
                    }
                }
            }
        }
        .padding(20)
        .onAppear {
            if appModel.selectedCue == nil {
                appModel.selectCue(appModel.visibleCues.first?.id)
            }
        }
        .onChange(of: appModel.isEditingCue) { _, isEditing in
            if isEditing {
                DispatchQueue.main.async {
                    isEditFieldFocused = true
                }
            } else {
                isEditFieldFocused = false
            }
        }
    }

    private var filtersBar: some View {
        HStack(spacing: 12) {
            Picker(
                localization.text("recording.active_actor"),
                selection: Binding(
                    get: { appModel.project?.activeActorFilterID },
                    set: { appModel.setActorFilter($0) }
                )
            ) {
                Text(localization.text("recording.no_actor_marking")).tag(Optional<UUID>.none)
                ForEach(appModel.actors) { actor in
                    Text(actor.displayName).tag(Optional(actor.id))
                }
            }
            .frame(width: 220)
            .disabled(appModel.isEditingCue)

            Picker(
                localization.text("recording.character"),
                selection: Binding(
                    get: { appModel.project?.activeCharacterFilterID },
                    set: { appModel.setCharacterFilter($0) }
                )
            ) {
                Text(localization.text("recording.all_characters")).tag(Optional<UUID>.none)
                ForEach(appModel.characters) { character in
                    Text(character.name).tag(Optional(character.id))
                }
            }
            .frame(width: 220)
            .disabled(appModel.isEditingCue)

            Toggle(
                localization.text("recording.only_unrecorded"),
                isOn: Binding(
                    get: { appModel.project?.showOnlyUnrecorded ?? false },
                    set: { appModel.setShowOnlyUnrecorded($0) }
                )
            )
            .toggleStyle(.switch)
            .disabled(appModel.isEditingCue)

            Toggle(
                localization.text("recording.hide_tc_frames"),
                isOn: Binding(
                    get: { appModel.hidesTimecodeFrames },
                    set: { appModel.setHideTimecodeFrames($0) }
                )
            )
            .toggleStyle(.switch)
            .disabled(appModel.isEditingCue)

            Stepper(
                value: Binding(
                    get: { appModel.displayContextCount },
                    set: { appModel.setDisplayContextCount($0) }
                ),
                in: 0...8
            ) {
                Text(localization.format("recording.display_context", appModel.displayContextCount))
                    .monospacedDigit()
            }
            .frame(width: 140, alignment: .leading)
            .disabled(appModel.isEditingCue)

            Spacer()

            if let activeActor = appModel.activeActor {
                Text(localization.format("recording.marked_for_actor", activeActor.displayName, appModel.activeActorMarkedCueCount))
                    .foregroundStyle(.orange)
                    .font(.callout.weight(.medium))
            }

            Text(localization.format("common.cue_count", appModel.visibleCues.count))
                .foregroundStyle(.secondary)
        }
    }

    private var controlsBar: some View {
        HStack(spacing: 12) {
            Button(localization.text("recording.previous")) {
                appModel.moveSelection(by: -1)
            }
            .disabled(appModel.isEditingCue)

            Button(localization.text("recording.record")) {
                appModel.markSelectedRecordedAndAdvance()
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.borderedProminent)
            .disabled(appModel.isEditingCue || !appModel.canTriggerRecordAdvance)

            Button(localization.text("recording.revert")) {
                appModel.unrecordSelectedCue()
            }
            .disabled(appModel.isEditingCue)

            Button(localization.text("recording.next")) {
                appModel.moveSelection(by: 1)
            }
            .disabled(appModel.isEditingCue)

            Button(localization.text("recording.edit")) {
                appModel.startEditingSelectedCue()
            }
            .disabled(!appModel.canStartCueEdit || appModel.isEditingCue)

            Spacer()

            if let selectedCue = appModel.selectedCue {
                Text(localization.format("common.cue_index", selectedCue.index))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if let controlHintText {
                Text(controlHintText)
                    .foregroundStyle(.orange)
                    .font(.callout.weight(.medium))
            }
        }
    }

    @ViewBuilder
    private var cueEditBar: some View {
        if let selectedCue = appModel.selectedCue {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Label(
                        appModel.isEditingCue ? localization.text("recording.quick_edit") : localization.text("recording.selected_line"),
                        systemImage: appModel.isEditingCue ? "pencil.circle.fill" : "text.quote"
                    )
                        .font(.headline)

                    Spacer()

                    Text("#\(selectedCue.index) · \(appModel.characterName(for: selectedCue.characterID)) · \(appModel.displayTimecode(selectedCue.inTimecode))")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                        .monospacedDigit()

                    if appModel.canRevertSelectedCueEdit {
                        Button(localization.text("recording.restore_original_text")) {
                            appModel.revertSelectedCueToOriginal()
                        }
                        .disabled(appModel.isEditingCue)
                    }
                }

                if appModel.isEditingCue {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.text("recording.original"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(appModel.displayDialoguePreview(appModel.originalDialogue(for: selectedCue)))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.text("recording.edited_line"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField(localization.text("recording.edit_placeholder"), text: $appModel.cueEditDraft)
                            .textFieldStyle(.roundedBorder)
                            .focused($isEditFieldFocused)
                            .onSubmit {
                                appModel.saveCueEditing()
                            }
                    }

                    HStack(spacing: 12) {
                        Text(localization.text("recording.enter_saves_escape_cancels"))
                            .foregroundStyle(.secondary)
                            .font(.callout)

                        Spacer()

                        Button(localization.text("common.cancel")) {
                            appModel.cancelCueEditing()
                        }
                        .keyboardShortcut(.cancelAction)

                        Button(localization.text("common.save")) {
                            appModel.saveCueEditing()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    HStack(spacing: 12) {
                        Text(appModel.displayDialogue(selectedCue))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if selectedCue.isEdited {
                            Label(localization.text("recording.badge.edited"), systemImage: "pencil")
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .padding(14)
            .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var cueHeader: some View {
        HStack(spacing: 12) {
            Text(localization.text("recording.status_header"))
                .frame(width: 90, alignment: .leading)
            Text(localization.text("recording.source_header"))
                .frame(width: 150, alignment: .leading)
            Text(localization.text("recording.character_header"))
                .frame(width: 170, alignment: .leading)
            Text(localization.text("recording.actor_header"))
                .frame(width: 150, alignment: .leading)
            Text(localization.text("recording.timecode_header"))
                .frame(width: 120, alignment: .leading)
            Text(localization.text("recording.text_header"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
    }

    private func cueRow(_ cue: Cue) -> some View {
        let isSelected = cue.id == appModel.project?.selectedCueID
        let isRecorded = cue.status == .recorded
        let isMarkedForActiveActor = appModel.isCueMarkedForActiveActor(cue)

        return HStack(spacing: 12) {
            Text(statusLabel(isRecorded: isRecorded, isSelected: isSelected))
                .frame(width: 90, alignment: .leading)
                .foregroundStyle(isRecorded ? .green : (isSelected ? .blue : .secondary))

            Text(cue.rawSource)
                .frame(width: 150, alignment: .leading)
                .font(.system(.body, design: .monospaced))

            Text(appModel.characterName(for: cue.characterID))
                .frame(width: 170, alignment: .leading)

            Text(appModel.actorName(for: appModel.actorID(forCharacterID: cue.characterID)))
                .frame(width: 150, alignment: .leading)
                .foregroundStyle(isMarkedForActiveActor ? .orange : .primary)

            Text(appModel.displayTimecode(cue.inTimecode))
                .frame(width: 120, alignment: .leading)
                .font(.system(.body, design: .monospaced))

            Text(appModel.displayDialogue(cue))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(cue.dialogue.isEmpty ? .secondary : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(background(isSelected: isSelected, isRecorded: isRecorded, isMarkedForActiveActor: isMarkedForActiveActor))
        .overlay(alignment: .leading) {
            if isMarkedForActiveActor {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.orange.opacity(isSelected ? 0.95 : 0.8))
                    .frame(width: 6)
                    .padding(.vertical, 8)
                    .padding(.leading, 4)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isMarkedForActiveActor ? Color.orange.opacity(0.45) : .clear, lineWidth: 1.5)
        }
        .contentShape(Rectangle())
    }

    private func background(
        isSelected: Bool,
        isRecorded: Bool,
        isMarkedForActiveActor: Bool
    ) -> some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(.blue.opacity(0.18))
        }
        if isRecorded {
            return AnyShapeStyle(.green.opacity(0.12))
        }
        if isMarkedForActiveActor {
            return AnyShapeStyle(.orange.opacity(0.10))
        }
        return AnyShapeStyle(.quaternary.opacity(0.28))
    }

    private var controlHintText: String? {
        if appModel.isEditingCue {
            return localization.text("recording.hint.editing")
        }

        if !appModel.hasActiveActorSelection {
            return localization.text("recording.hint.select_actor")
        }

        if !appModel.canTriggerRecordAdvance {
            return localization.text("recording.hint.none_left")
        }

        guard let selectedCue = appModel.selectedCue else {
            return localization.text("recording.hint.jump_next")
        }

        if !appModel.isCueMarkedForActiveActor(selectedCue) {
            return localization.text("recording.hint.other_actor")
        }

        if selectedCue.status == .recorded {
            return localization.text("recording.hint.already_recorded")
        }

        return nil
    }

    private func statusLabel(isRecorded: Bool, isSelected: Bool) -> String {
        if isRecorded {
            return localization.text("recording.status.recorded")
        }

        if isSelected {
            return localization.text("recording.status.selected")
        }

        return localization.text("recording.status.waiting")
    }
}
