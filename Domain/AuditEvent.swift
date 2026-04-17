import Foundation

enum AuditEventType: String, Codable, Sendable {
    case projectImported
    case actorAssigned
    case cueSelected
    case cueEdited
    case cueEditReverted
    case cueRecorded
    case cueUnrecorded
    case projectSaved
    case projectExported
}

struct AuditEvent: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var timestamp: Date
    var type: AuditEventType
    var cueID: UUID?
    var actorID: UUID?
    var payload: [String: String]

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        type: AuditEventType,
        cueID: UUID? = nil,
        actorID: UUID? = nil,
        payload: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.cueID = cueID
        self.actorID = actorID
        self.payload = payload
    }
}
