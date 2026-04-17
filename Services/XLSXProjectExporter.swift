import Foundation

struct XLSXProjectExporter {
    func export(
        project: DubProject,
        summaries: [CharacterSummary],
        to destinationURL: URL,
        actorNameResolver: (UUID?) -> String?,
        characterNameResolver: (UUID) -> String?
    ) throws {
        let fileManager = FileManager.default
        let rootURL = fileManager.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let workbookURL = rootURL.appending(path: "xl", directoryHint: .isDirectory)
        let worksheetsURL = workbookURL.appending(path: "worksheets", directoryHint: .isDirectory)
        let relsURL = rootURL.appending(path: "_rels", directoryHint: .isDirectory)
        let workbookRelsURL = workbookURL.appending(path: "_rels", directoryHint: .isDirectory)

        try fileManager.createDirectory(at: worksheetsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: relsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: workbookRelsURL, withIntermediateDirectories: true)

        let cueRows = buildCueRows(project: project, actorNameResolver: actorNameResolver, characterNameResolver: characterNameResolver)
        let summaryRows = buildSummaryRows(summaries: summaries)

        try write(
            """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
              <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
              <Default Extension="xml" ContentType="application/xml"/>
              <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
              <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
              <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
              <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
            </Types>
            """,
            to: rootURL.appending(path: "[Content_Types].xml")
        )

        try write(
            """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
              <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
            </Relationships>
            """,
            to: relsURL.appending(path: ".rels")
        )

        try write(
            """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
              <sheets>
                <sheet name="Cue Status" sheetId="1" r:id="rId1"/>
                <sheet name="Character Summary" sheetId="2" r:id="rId2"/>
              </sheets>
            </workbook>
            """,
            to: workbookURL.appending(path: "workbook.xml")
        )

        try write(
            """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
              <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
              <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
              <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
            </Relationships>
            """,
            to: workbookRelsURL.appending(path: "workbook.xml.rels")
        )

        try write(minimalStylesXML(), to: workbookURL.appending(path: "styles.xml"))
        try write(worksheetXML(rows: cueRows), to: worksheetsURL.appending(path: "sheet1.xml"))
        try write(worksheetXML(rows: summaryRows), to: worksheetsURL.appending(path: "sheet2.xml"))

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try ShellCommand.run(
            executable: "/usr/bin/zip",
            arguments: ["-qry", destinationURL.path, "."],
            currentDirectoryURL: rootURL
        )

        try? fileManager.removeItem(at: rootURL)
    }

    private func buildCueRows(
        project: DubProject,
        actorNameResolver: (UUID?) -> String?,
        characterNameResolver: (UUID) -> String?
    ) -> [[String]] {
        var rows: [[String]] = [[
            "Index",
            "SOURCE",
            "Character",
            "Assigned Actor",
            "IN-TIMECODE",
            "DIALOGUE",
            "Word Count",
            "Status",
            "Recorded At"
        ]]

        for cue in project.cues.sorted(by: { $0.index < $1.index }) {
            rows.append([
                "\(cue.index)",
                cue.rawSource,
                characterNameResolver(cue.characterID) ?? "",
                actorNameResolver(project.characters.first(where: { $0.id == cue.characterID })?.assignedActorID) ?? "",
                cue.inTimecode,
                cue.dialogue,
                "\(cue.wordCount)",
                cue.status.rawValue,
                cue.recordedAt.map(DateFormatting.exportFormatter.string(from:)) ?? ""
            ])
        }

        return rows
    }

    private func buildSummaryRows(summaries: [CharacterSummary]) -> [[String]] {
        var rows: [[String]] = [[
            "Character",
            "Assigned Actor",
            "Cue Count",
            "Word Count",
            "Planned Takes",
            "Recorded Cues",
            "Remaining Cues",
            "Recorded %"
        ]]

        for summary in summaries {
            rows.append([
                summary.character.name,
                summary.actor?.displayName ?? "",
                "\(summary.cueCount)",
                "\(summary.wordCount)",
                "\(summary.plannedTakes)",
                "\(summary.recordedCueCount)",
                "\(summary.remainingCueCount)",
                String(format: "%.2f%%", summary.recordedRatio * 100)
            ])
        }

        return rows
    }

    private func worksheetXML(rows: [[String]]) -> String {
        let body = rows.enumerated().map { rowIndex, row in
            let cells = row.enumerated().map { columnIndex, value in
                let reference = "\(columnName(for: columnIndex + 1))\(rowIndex + 1)"
                return """
                <c r="\(reference)" t="inlineStr"><is><t xml:space="preserve">\(escapeXML(value))</t></is></c>
                """
            }.joined()

            return "<row r=\"\(rowIndex + 1)\">\(cells)</row>"
        }.joined()

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetData>\(body)</sheetData>
        </worksheet>
        """
    }

    private func minimalStylesXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <fonts count="1">
            <font>
              <sz val="11"/>
              <name val="Helvetica Neue"/>
            </font>
          </fonts>
          <fills count="1">
            <fill><patternFill patternType="none"/></fill>
          </fills>
          <borders count="1">
            <border/>
          </borders>
          <cellStyleXfs count="1">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
          </cellStyleXfs>
          <cellXfs count="1">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
          </cellXfs>
        </styleSheet>
        """
    }

    private func write(_ string: String, to url: URL) throws {
        try Data(string.utf8).write(to: url)
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func columnName(for number: Int) -> String {
        var value = number
        var result = ""
        while value > 0 {
            let modulo = (value - 1) % 26
            result = String(UnicodeScalar(65 + modulo)!) + result
            value = (value - 1) / 26
        }
        return result
    }
}
