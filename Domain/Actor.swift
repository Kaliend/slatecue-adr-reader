import Foundation

struct Actor: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var displayName: String
    var notes: String

    init(id: UUID = UUID(), displayName: String, notes: String = "") {
        self.id = id
        self.displayName = displayName
        self.notes = notes
    }
}
