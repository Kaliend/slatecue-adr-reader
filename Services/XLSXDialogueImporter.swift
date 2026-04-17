import Foundation

enum XLSXDialogueImporterError: LocalizedError {
    case missingDialogueSheet
    case unreadableWorkbook

    var errorDescription: String? {
        switch self {
        case .missingDialogueSheet:
            return AppStrings.currentText("error.xlsx_missing_dialogue_sheet")
        case .unreadableWorkbook:
            return AppStrings.currentText("error.xlsx_unreadable_workbook")
        }
    }
}

struct XLSXDialogueImporter {
    func importProject(from url: URL) throws -> DubProject {
        let sharedStrings = try loadSharedStrings(from: url)
        let worksheetPath = try locateDialogueWorksheetPath(in: url)
        let worksheetData = try ShellCommand.run(
            executable: "/usr/bin/unzip",
            arguments: ["-p", url.path, worksheetPath]
        )
        let worksheet = try XMLDocument(data: worksheetData, options: [])
        let rows = try xmlNodes(
            from: worksheet,
            xpath: "//*[local-name()='sheetData']/*[local-name()='row']"
        )

        guard let headerRow = rows.first else {
            throw XLSXDialogueImporterError.unreadableWorkbook
        }

        let headerMap = try parseRow(headerRow, sharedStrings: sharedStrings)
        let normalizedHeaders = headerMap.reduce(into: [String: String]()) { partialResult, pair in
            partialResult[pair.key] = normalizeHeader(pair.value)
        }

        let sourceColumn = normalizedHeaders.first(where: { $0.value == "SOURCE" })?.key
        let inTimecodeColumn = normalizedHeaders.first(where: { $0.value == "IN-TIMECODE" })?.key
        let dialogueColumn = normalizedHeaders.first(where: { $0.value == "DIALOGUE" })?.key

        var charactersByName: [String: Character] = [:]
        var cues: [Cue] = []

        for rowNode in rows.dropFirst() {
            let row = try parseRow(rowNode, sharedStrings: sharedStrings)
            let rawSource = sourceColumn.flatMap { row[$0] }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let inTimecode = inTimecodeColumn.flatMap { row[$0] }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let dialogue = dialogueColumn.flatMap { row[$0] } ?? ""

            if rawSource.isEmpty, inTimecode.isEmpty, dialogue.isEmpty {
                continue
            }

            let characterName = normalizeCharacterName(from: rawSource)
            var character = charactersByName[characterName] ?? Character(name: characterName, rawSourceSamples: [])
            if !rawSource.isEmpty, !character.rawSourceSamples.contains(rawSource) {
                character.rawSourceSamples.append(rawSource)
            }
            charactersByName[characterName] = character

            let wordCount = dialogue
                .split(whereSeparator: \.isWhitespace)
                .count

            cues.append(
                Cue(
                    index: cues.count + 1,
                    rawSource: rawSource,
                    characterID: character.id,
                    inTimecode: inTimecode,
                    dialogue: dialogue,
                    wordCount: wordCount
                )
            )
        }

        let projectName = url.deletingPathExtension().lastPathComponent
        return DubProject(
            name: projectName,
            sourceFileName: url.lastPathComponent,
            selectedCueID: cues.first?.id,
            actors: [],
            characters: Array(charactersByName.values).sorted { $0.name < $1.name },
            cues: cues
        )
    }

    private func locateDialogueWorksheetPath(in url: URL) throws -> String {
        let workbookData = try ShellCommand.run(
            executable: "/usr/bin/unzip",
            arguments: ["-p", url.path, "xl/workbook.xml"]
        )
        let relationshipsData = try ShellCommand.run(
            executable: "/usr/bin/unzip",
            arguments: ["-p", url.path, "xl/_rels/workbook.xml.rels"]
        )

        let workbook = try XMLDocument(data: workbookData, options: [])
        let relationships = try XMLDocument(data: relationshipsData, options: [])
        let relationshipNodes = try xmlNodes(
            from: relationships,
            xpath: "//*[local-name()='Relationship']"
        )
        let relationMap = relationshipNodes.reduce(into: [String: String]()) { partialResult, node in
            guard let element = node as? XMLElement,
                  let id = element.attribute(forName: "Id")?.stringValue,
                  let target = element.attribute(forName: "Target")?.stringValue else {
                return
            }
            partialResult[id] = target
        }

        let sheetNodes = try xmlNodes(from: workbook, xpath: "//*[local-name()='sheet']")
        for node in sheetNodes {
            guard let element = node as? XMLElement else { continue }
            let name = element.attribute(forName: "name")?.stringValue
            let relationshipID =
                element.attribute(forName: "r:id")?.stringValue ??
                element.attribute(forLocalName: "id", uri: "http://schemas.openxmlformats.org/officeDocument/2006/relationships")?.stringValue

            guard name == "Dialogue List", let relationshipID, let target = relationMap[relationshipID] else {
                continue
            }

            if target.hasPrefix("xl/") {
                return target
            }
            return "xl/\(target)"
        }

        throw XLSXDialogueImporterError.missingDialogueSheet
    }

    private func loadSharedStrings(from url: URL) throws -> [String] {
        let data = try? ShellCommand.run(
            executable: "/usr/bin/unzip",
            arguments: ["-p", url.path, "xl/sharedStrings.xml"]
        )
        guard let data else {
            return []
        }

        let document = try XMLDocument(data: data, options: [])
        let nodes = try xmlNodes(from: document, xpath: "//*[local-name()='si']")
        return try nodes.map { node in
            let textNodes = try xmlNodes(from: node, xpath: ".//*[local-name()='t']")
            return textNodes
                .compactMap(\.stringValue)
                .joined()
        }
    }

    private func parseRow(_ rowNode: XMLNode, sharedStrings: [String]) throws -> [String: String] {
        let cells = try xmlNodes(from: rowNode, xpath: "./*[local-name()='c']")
        return try cells.reduce(into: [String: String]()) { partialResult, node in
            guard let element = node as? XMLElement,
                  let reference = element.attribute(forName: "r")?.stringValue else {
                return
            }

            let column = reference.prefix { $0.isLetter }
            let type = element.attribute(forName: "t")?.stringValue
            let value: String

            switch type {
            case "s":
                let rawIndex = try xmlNodes(from: element, xpath: "./*[local-name()='v']").first?.stringValue ?? ""
                let index = Int(rawIndex) ?? 0
                value = sharedStrings.indices.contains(index) ? sharedStrings[index] : ""
            case "inlineStr":
                let textNodes = try xmlNodes(from: element, xpath: ".//*[local-name()='t']")
                value = textNodes.compactMap(\.stringValue).joined()
            default:
                value = try xmlNodes(from: element, xpath: "./*[local-name()='v']").first?.stringValue ?? ""
            }

            partialResult[String(column)] = value
        }
    }

    private func normalizeHeader(_ rawValue: String) -> String {
        rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private func normalizeCharacterName(from rawSource: String) -> String {
        let stripped = rawSource
            .replacingOccurrences(of: #"^\d+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return stripped.isEmpty ? rawSource : stripped
    }

    private func xmlNodes(from node: XMLNode, xpath: String) throws -> [XMLNode] {
        try node.nodes(forXPath: xpath)
    }
}
