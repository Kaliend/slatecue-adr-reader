import Foundation

struct DubProject: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var sourceFileName: String
    var selectedCueID: UUID?
    var activeActorFilterID: UUID?
    var activeCharacterFilterID: UUID?
    var showOnlyUnrecorded: Bool
    var hideTimecodeFrames: Bool
    var displayContextCount: Int
    var actors: [Actor]
    var characters: [Character]
    var cues: [Cue]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sourceFileName: String,
        selectedCueID: UUID? = nil,
        activeActorFilterID: UUID? = nil,
        activeCharacterFilterID: UUID? = nil,
        showOnlyUnrecorded: Bool = false,
        hideTimecodeFrames: Bool = false,
        displayContextCount: Int = 2,
        actors: [Actor] = [],
        characters: [Character] = [],
        cues: [Cue] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceFileName = sourceFileName
        self.selectedCueID = selectedCueID
        self.activeActorFilterID = activeActorFilterID
        self.activeCharacterFilterID = activeCharacterFilterID
        self.showOnlyUnrecorded = showOnlyUnrecorded
        self.hideTimecodeFrames = hideTimecodeFrames
        self.displayContextCount = max(displayContextCount, 0)
        self.actors = actors
        self.characters = cues.isEmpty ? characters : characters.sorted { $0.name < $1.name }
        self.cues = cues.sorted { $0.index < $1.index }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case updatedAt
        case sourceFileName
        case selectedCueID
        case activeActorFilterID
        case activeCharacterFilterID
        case showOnlyUnrecorded
        case hideTimecodeFrames
        case displayContextCount
        case actors
        case characters
        case cues
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        sourceFileName = try container.decode(String.self, forKey: .sourceFileName)
        selectedCueID = try container.decodeIfPresent(UUID.self, forKey: .selectedCueID)
        activeActorFilterID = try container.decodeIfPresent(UUID.self, forKey: .activeActorFilterID)
        activeCharacterFilterID = try container.decodeIfPresent(UUID.self, forKey: .activeCharacterFilterID)
        showOnlyUnrecorded = try container.decodeIfPresent(Bool.self, forKey: .showOnlyUnrecorded) ?? false
        hideTimecodeFrames = try container.decodeIfPresent(Bool.self, forKey: .hideTimecodeFrames) ?? false
        displayContextCount = max(try container.decodeIfPresent(Int.self, forKey: .displayContextCount) ?? 2, 0)
        actors = try container.decodeIfPresent([Actor].self, forKey: .actors) ?? []
        let decodedCharacters = try container.decodeIfPresent([Character].self, forKey: .characters) ?? []
        let decodedCues = try container.decodeIfPresent([Cue].self, forKey: .cues) ?? []
        characters = decodedCues.isEmpty ? decodedCharacters : decodedCharacters.sorted { $0.name < $1.name }
        cues = decodedCues.sorted { $0.index < $1.index }
    }
}
