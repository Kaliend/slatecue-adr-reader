import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published var project: DubProject?
    @Published var auditEvents: [AuditEvent] = []
    @Published var activeSection: ControlSection = .preparation
    @Published var currentProjectURL: URL?
    @Published var sourceXLSXURL: URL?
    @Published var isBusy = false
    @Published var alertMessage: String?
    @Published var editingCueID: UUID?
    @Published var cueEditDraft = ""

    private let localization: LocalizationController
    private let importer = XLSXDialogueImporter()
    private let exporter = XLSXProjectExporter()
    private let packageStore = ProjectPackageStore()

    init(localization: LocalizationController) {
        self.localization = localization
    }

    var actors: [Actor] {
        guard let project else { return [] }
        return project.actors.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    var characters: [Character] {
        guard let project else { return [] }
        return project.characters.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var selectedCue: Cue? {
        guard let project, let selectedCueID = project.selectedCueID else { return nil }
        return project.cues.first(where: { $0.id == selectedCueID })
    }

    var editingCue: Cue? {
        guard let project, let editingCueID else { return nil }
        return project.cues.first(where: { $0.id == editingCueID })
    }

    var activeActor: Actor? {
        guard let activeActorID = project?.activeActorFilterID else { return nil }
        return actors.first(where: { $0.id == activeActorID })
    }

    var activeActorMarkedCueCount: Int {
        guard let activeActorID = project?.activeActorFilterID else { return 0 }
        return project?.cues.filter { actorID(forCharacterID: $0.characterID) == activeActorID }.count ?? 0
    }

    var hasActiveActorSelection: Bool {
        project?.activeActorFilterID != nil
    }

    var activeActorRecordableCueCount: Int {
        visibleCues.filter { isCueMarkedForActiveActor($0) && $0.status != .recorded }.count
    }

    var hidesTimecodeFrames: Bool {
        project?.hideTimecodeFrames ?? false
    }

    var displayContextCount: Int {
        max(project?.displayContextCount ?? 2, 0)
    }

    var canTriggerRecordAdvance: Bool {
        hasActiveActorSelection && activeActorRecordableCueCount > 0
    }

    var canRecordSelectedCue: Bool {
        guard let selectedCue else { return false }
        return hasActiveActorSelection && isCueMarkedForActiveActor(selectedCue) && selectedCue.status != .recorded
    }

    var isEditingCue: Bool {
        editingCueID != nil
    }

    var canStartCueEdit: Bool {
        selectedCue != nil && !isBusy
    }

    var canRevertSelectedCueEdit: Bool {
        selectedCue?.originalDialogue != nil
    }

    var displayContext: (previous: [Cue], current: Cue, next: [Cue])? {
        displayContext(for: displayContextCount)
    }

    func displayContext(for contextCount: Int) -> (previous: [Cue], current: Cue, next: [Cue])? {
        guard let project,
              let selectedCueID = project.selectedCueID,
              let currentIndex = project.cues.firstIndex(where: { $0.id == selectedCueID }) else {
            return nil
        }

        let clampedContextCount = max(contextCount, 0)
        let previousStart = max(currentIndex - clampedContextCount, 0)
        let nextEnd = min(currentIndex + clampedContextCount + 1, project.cues.count)
        let previousCues = Array(project.cues[previousStart..<currentIndex])
        let currentCue = project.cues[currentIndex]
        let nextCues = currentIndex < project.cues.count - 1
            ? Array(project.cues[(currentIndex + 1)..<nextEnd])
            : []

        return (previous: previousCues, current: currentCue, next: nextCues)
    }

    var visibleCues: [Cue] {
        guard let project else { return [] }

        return project.cues.filter { cue in
            if project.showOnlyUnrecorded && cue.status == .recorded {
                return false
            }

            if let activeCharacterFilterID = project.activeCharacterFilterID, cue.characterID != activeCharacterFilterID {
                return false
            }

            return true
        }
    }

    var navigableCues: [Cue] {
        guard hasActiveActorSelection else {
            return visibleCues
        }

        return visibleCues.filter { isCueMarkedForActiveActor($0) }
    }

    var characterSummaries: [CharacterSummary] {
        guard let project else { return [] }

        return characters.map { character in
            let cues = project.cues.filter { $0.characterID == character.id }
            let wordCount = cues.reduce(into: 0) { partialResult, cue in
                partialResult += cue.wordCount
            }
            let recordedCueCount = cues.filter { $0.status == .recorded }.count
            let cueCount = cues.count
            let remainingCueCount = max(cueCount - recordedCueCount, 0)
            let plannedTakes = Int(ceil(Double(wordCount) / 8.0))
            let actor = actors.first(where: { $0.id == character.assignedActorID })
            let ratio = cueCount == 0 ? 0 : Double(recordedCueCount) / Double(cueCount)

            return CharacterSummary(
                id: character.id,
                character: character,
                actor: actor,
                cueCount: cueCount,
                wordCount: wordCount,
                plannedTakes: plannedTakes,
                recordedCueCount: recordedCueCount,
                remainingCueCount: remainingCueCount,
                recordedRatio: ratio
            )
        }
    }

    func loadDemoProject() {
        project = DemoData.sampleProject(language: localization.language)
        currentProjectURL = nil
        sourceXLSXURL = nil
        auditEvents = []
        activeSection = .preparation
        cancelCueEditing()
    }

    func importXLSXInteractive() {
        let panel = NSOpenPanel()
        panel.title = localization.text("panel.import_xlsx.title")
        panel.prompt = localization.text("panel.import_xlsx.prompt")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(filenameExtension: "xlsx") ?? .data]

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        importXLSX(from: url)
    }

    func importXLSX(from url: URL) {
        isBusy = true

        Task {
            defer { isBusy = false }

            do {
                var importedProject = try await Task.detached(priority: .userInitiated) {
                    try XLSXDialogueImporter().importProject(from: url)
                }.value

                importedProject.selectedCueID = importedProject.cues.first?.id
                project = importedProject
                sourceXLSXURL = url
                currentProjectURL = nil
                cancelCueEditing()
                auditEvents = [
                    AuditEvent(
                        type: .projectImported,
                        payload: ["sourceFile": url.lastPathComponent]
                    )
                ]
                activeSection = .preparation
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    func openProjectInteractive() {
        let panel = NSOpenPanel()
        panel.title = localization.text("panel.open_project.title")
        panel.prompt = localization.text("panel.open_project.prompt")
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        openProject(from: url)
    }

    func openProject(from url: URL) {
        do {
            let package = try packageStore.load(from: url)
            project = package.project
            auditEvents = package.auditEvents
            sourceXLSXURL = package.sourceXLSXURL
            currentProjectURL = url
            cancelCueEditing()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func saveProjectInteractive() {
        if currentProjectURL == nil {
            saveProjectAsInteractive()
            return
        }

        guard let currentProjectURL else { return }
        saveProject(to: currentProjectURL)
    }

    func saveProjectAsInteractive() {
        guard let project else { return }
        let panel = NSSavePanel()
        panel.title = localization.text("panel.save_project.title")
        panel.prompt = localization.text("panel.save_project.prompt")
        panel.nameFieldStringValue = "\(project.name).slatecue"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, var url = panel.url else {
            return
        }

        if url.pathExtension.lowercased() != "slatecue" {
            url.appendPathExtension("slatecue")
        }

        saveProject(to: url)
    }

    func saveProject(to url: URL) {
        guard var project else { return }

        do {
            project.updatedAt = .now
            self.project = project
            appendAuditEvent(.init(type: .projectSaved, payload: ["file": url.lastPathComponent]))
            try packageStore.save(
                project: project,
                auditEvents: auditEvents,
                sourceXLSXURL: sourceXLSXURL,
                to: url
            )
            currentProjectURL = url
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func exportStatusInteractive() {
        guard let project else { return }

        let panel = NSSavePanel()
        panel.title = localization.text("panel.export_xlsx.title")
        panel.prompt = localization.text("panel.export_xlsx.prompt")
        panel.nameFieldStringValue = "\(project.name)-status.xlsx"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, var url = panel.url else {
            return
        }

        if url.pathExtension.lowercased() != "xlsx" {
            url.appendPathExtension("xlsx")
        }

        do {
            try exporter.export(project: project, summaries: characterSummaries, to: url, actorNameResolver: { [weak self] actorID in
                guard let self else { return nil }
                return self.actors.first(where: { $0.id == actorID })?.displayName
            }, characterNameResolver: { [weak self] characterID in
                guard let self else { return nil }
                return self.characters.first(where: { $0.id == characterID })?.name
            })
            appendAuditEvent(.init(type: .projectExported, payload: ["file": url.lastPathComponent]))
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func createActor(named name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        mutateProject { project in
            project.actors.append(Actor(displayName: name.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
    }

    func assignActor(_ actorID: UUID?, to characterID: UUID) {
        mutateProject { project in
            guard let index = project.characters.firstIndex(where: { $0.id == characterID }) else {
                return
            }

            project.characters[index].assignedActorID = actorID
        }

        appendAuditEvent(.init(type: .actorAssigned, actorID: actorID, payload: ["characterID": characterID.uuidString]))
    }

    func selectCue(_ cueID: UUID?) {
        if isEditingCue {
            guard cueID == editingCueID else {
                return
            }
        }

        mutateProject { project in
            project.selectedCueID = cueID
        }

        if let cueID {
            appendAuditEvent(.init(type: .cueSelected, cueID: cueID))
        }
    }

    func setActorFilter(_ actorID: UUID?) {
        guard !isEditingCue else { return }
        mutateProject { project in
            project.activeActorFilterID = actorID
        }
        ensureSelectedCueIsVisible()
    }

    func setCharacterFilter(_ characterID: UUID?) {
        guard !isEditingCue else { return }
        mutateProject { project in
            project.activeCharacterFilterID = characterID
        }
        ensureSelectedCueIsVisible()
    }

    func setShowOnlyUnrecorded(_ value: Bool) {
        guard !isEditingCue else { return }
        mutateProject { project in
            project.showOnlyUnrecorded = value
        }
        ensureSelectedCueIsVisible()
    }

    func setHideTimecodeFrames(_ value: Bool) {
        guard !isEditingCue else { return }
        mutateProject { project in
            project.hideTimecodeFrames = value
        }
    }

    func setDisplayContextCount(_ value: Int) {
        guard !isEditingCue else { return }
        mutateProject { project in
            project.displayContextCount = max(value, 0)
        }
    }

    func moveSelection(by offset: Int) {
        guard !isEditingCue else { return }

        let visible = visibleCues
        guard !visible.isEmpty else {
            selectCue(nil)
            return
        }

        let navigable = navigableCues
        guard !navigable.isEmpty else {
            return
        }
        let navigableCueIDs = Set(navigable.map(\.id))

        guard let selectedCueID = project?.selectedCueID,
              let selectedVisibleIndex = visible.firstIndex(where: { $0.id == selectedCueID }) else {
            selectCue(offset >= 0 ? navigable.first?.id : navigable.last?.id)
            return
        }

        if let currentNavigableIndex = navigable.firstIndex(where: { $0.id == selectedCueID }) {
            let nextIndex = min(max(currentNavigableIndex + offset, 0), navigable.count - 1)
            selectCue(navigable[nextIndex].id)
            return
        }

        if offset >= 0 {
            let laterCue = visible
                .dropFirst(selectedVisibleIndex + 1)
                .first(where: { cue in navigableCueIDs.contains(cue.id) })
            selectCue(laterCue?.id ?? navigable.last?.id)
            return
        }

        let previousCue = visible[..<selectedVisibleIndex]
            .last(where: { cue in navigableCueIDs.contains(cue.id) })
        selectCue(previousCue?.id ?? navigable.first?.id)
    }

    func markSelectedRecordedAndAdvance() {
        guard !isEditingCue else { return }

        guard hasActiveActorSelection else {
            alertMessage = localization.text("alert.select_actor_first")
            return
        }

        guard canTriggerRecordAdvance else {
            return
        }

        guard let selectedCue else {
            selectCue(nextRecordableCueID(after: nil))
            return
        }

        guard isCueMarkedForActiveActor(selectedCue) else {
            selectCue(nextRecordableCueID(after: selectedCue.id))
            return
        }

        if selectedCue.status != .recorded {
            mutateProject { project in
                guard let cueIndex = project.cues.firstIndex(where: { $0.id == selectedCue.id }) else {
                    return
                }

                project.cues[cueIndex].status = .recorded
                project.cues[cueIndex].recordedAt = .now
            }

            appendAuditEvent(.init(type: .cueRecorded, cueID: selectedCue.id))
        }

        selectCue(nextRecordableCueID(after: selectedCue.id))
    }

    func unrecordSelectedCue() {
        guard !isEditingCue else { return }

        guard let selectedCueID = project?.selectedCueID else {
            return
        }

        mutateProject { project in
            guard let cueIndex = project.cues.firstIndex(where: { $0.id == selectedCueID }) else {
                return
            }

            project.cues[cueIndex].status = .idle
            project.cues[cueIndex].recordedAt = nil
        }

        appendAuditEvent(.init(type: .cueUnrecorded, cueID: selectedCueID))
    }

    func actorName(for actorID: UUID?) -> String {
        guard let actorID else { return localization.text("common.unassigned") }
        return actors.first(where: { $0.id == actorID })?.displayName ?? localization.text("common.unassigned")
    }

    func startEditingSelectedCue() {
        guard let selectedCue, canStartCueEdit else {
            return
        }

        editingCueID = selectedCue.id
        cueEditDraft = selectedCue.dialogue
    }

    func cancelCueEditing() {
        editingCueID = nil
        cueEditDraft = ""
    }

    func saveCueEditing() {
        guard let editingCue else {
            cancelCueEditing()
            return
        }

        let updatedDialogue = cueEditDraft
        if updatedDialogue == editingCue.dialogue {
            cancelCueEditing()
            return
        }

        let originalDialogue = editingCue.originalDialogue ?? editingCue.dialogue
        let isRevertingToOriginal = updatedDialogue == originalDialogue

        mutateProject { project in
            guard let cueIndex = project.cues.firstIndex(where: { $0.id == editingCue.id }) else {
                return
            }

            project.cues[cueIndex].dialogue = updatedDialogue
            project.cues[cueIndex].wordCount = wordCount(for: updatedDialogue)

            if isRevertingToOriginal {
                project.cues[cueIndex].originalDialogue = nil
                project.cues[cueIndex].editedAt = nil
            } else {
                project.cues[cueIndex].originalDialogue = originalDialogue
                project.cues[cueIndex].editedAt = .now
            }
        }

        appendAuditEvent(
            .init(
                type: isRevertingToOriginal ? .cueEditReverted : .cueEdited,
                cueID: editingCue.id,
                payload: ["wordCount": String(wordCount(for: updatedDialogue))]
            )
        )
        cancelCueEditing()
    }

    func revertSelectedCueToOriginal() {
        guard let selectedCue,
              let originalDialogue = selectedCue.originalDialogue else {
            return
        }

        mutateProject { project in
            guard let cueIndex = project.cues.firstIndex(where: { $0.id == selectedCue.id }) else {
                return
            }

            project.cues[cueIndex].dialogue = originalDialogue
            project.cues[cueIndex].originalDialogue = nil
            project.cues[cueIndex].wordCount = wordCount(for: originalDialogue)
            project.cues[cueIndex].editedAt = nil
        }

        appendAuditEvent(
            .init(
                type: .cueEditReverted,
                cueID: selectedCue.id,
                payload: ["wordCount": String(wordCount(for: originalDialogue))]
            )
        )

        if editingCueID == selectedCue.id {
            cancelCueEditing()
        }
    }

    func originalDialogue(for cue: Cue) -> String {
        cue.originalDialogue ?? cue.dialogue
    }

    func displayDialogue(_ cue: Cue) -> String {
        cue.dialogue.isEmpty ? localization.text("common.empty_cue") : cue.dialogue
    }

    func displayDialoguePreview(_ dialogue: String) -> String {
        dialogue.isEmpty ? localization.text("common.empty_cue") : dialogue
    }

    func displayTimecode(_ rawTimecode: String) -> String {
        guard hidesTimecodeFrames else {
            return rawTimecode
        }

        let trimmed = rawTimecode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return rawTimecode
        }

        let separator = trimmed.contains(";") ? ";" : ":"
        let components = trimmed.components(separatedBy: separator)
        guard components.count == 4 else {
            return rawTimecode
        }

        return components.dropLast().joined(separator: separator)
    }

    func isCueMarkedForActiveActor(_ cue: Cue) -> Bool {
        guard let activeActorID = project?.activeActorFilterID else {
            return false
        }

        return actorID(forCharacterID: cue.characterID) == activeActorID
    }

    func actorID(forCharacterID characterID: UUID) -> UUID? {
        characters.first(where: { $0.id == characterID })?.assignedActorID
    }

    func characterName(for characterID: UUID) -> String {
        characters.first(where: { $0.id == characterID })?.name ?? "?"
    }

    private func nextRecordableCueID(after cueID: UUID?) -> UUID? {
        let candidates = visibleCues.filter { isCueMarkedForActiveActor($0) && $0.status != .recorded }
        guard !candidates.isEmpty else { return nil }

        guard let cueID,
              let currentIndex = visibleCues.firstIndex(where: { $0.id == cueID }) else {
            return candidates.first?.id
        }

        let trailingSlice = visibleCues.dropFirst(currentIndex + 1)
        if let laterMatch = trailingSlice.first(where: { isCueMarkedForActiveActor($0) && $0.status != .recorded }) {
            return laterMatch.id
        }

        return candidates.first?.id
    }

    private func ensureSelectedCueIsVisible() {
        guard let project else { return }

        if let selectedCueID = project.selectedCueID,
           visibleCues.contains(where: { $0.id == selectedCueID }) {
            return
        }

        selectCue(visibleCues.first?.id)
    }

    private func mutateProject(_ mutate: (inout DubProject) -> Void) {
        guard var project else { return }
        mutate(&project)
        project.updatedAt = .now
        self.project = project
    }

    private func appendAuditEvent(_ event: AuditEvent) {
        auditEvents.append(event)
    }

    private func wordCount(for dialogue: String) -> Int {
        dialogue.split(whereSeparator: \.isWhitespace).count
    }
}
