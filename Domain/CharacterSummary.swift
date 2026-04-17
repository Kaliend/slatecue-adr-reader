import Foundation

struct CharacterSummary: Identifiable, Hashable, Sendable {
    var id: UUID
    var character: Character
    var actor: Actor?
    var cueCount: Int
    var wordCount: Int
    var plannedTakes: Int
    var recordedCueCount: Int
    var remainingCueCount: Int
    var recordedRatio: Double
}
