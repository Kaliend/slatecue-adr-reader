import Foundation

struct Character: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var rawSourceSamples: [String]
    var assignedActorID: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        rawSourceSamples: [String] = [],
        assignedActorID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.rawSourceSamples = rawSourceSamples
        self.assignedActorID = assignedActorID
    }
}
