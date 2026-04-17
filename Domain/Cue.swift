import Foundation

struct Cue: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var index: Int
    var rawSource: String
    var characterID: UUID
    var inTimecode: String
    var dialogue: String
    var originalDialogue: String?
    var wordCount: Int
    var status: CueStatus
    var recordedAt: Date?
    var editedAt: Date?

    init(
        id: UUID = UUID(),
        index: Int,
        rawSource: String,
        characterID: UUID,
        inTimecode: String,
        dialogue: String,
        originalDialogue: String? = nil,
        wordCount: Int,
        status: CueStatus = .idle,
        recordedAt: Date? = nil,
        editedAt: Date? = nil
    ) {
        self.id = id
        self.index = index
        self.rawSource = rawSource
        self.characterID = characterID
        self.inTimecode = inTimecode
        self.dialogue = dialogue
        self.originalDialogue = originalDialogue
        self.wordCount = wordCount
        self.status = status
        self.recordedAt = recordedAt
        self.editedAt = editedAt
    }

    var isEdited: Bool {
        originalDialogue != nil
    }
}
