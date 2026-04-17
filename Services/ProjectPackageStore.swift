import Foundation

struct ProjectPackage {
    var project: DubProject
    var auditEvents: [AuditEvent]
    var sourceXLSXURL: URL?
}

enum ProjectPackageStoreError: LocalizedError {
    case missingManifest

    var errorDescription: String? {
        switch self {
        case .missingManifest:
            return AppStrings.currentText("error.missing_manifest")
        }
    }
}

struct ProjectPackageStore {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func save(
        project: DubProject,
        auditEvents: [AuditEvent],
        sourceXLSXURL: URL?,
        to destinationURL: URL
    ) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        let sourceDirectory = destinationURL.appending(path: "source", directoryHint: .isDirectory)
        let exportsDirectory = destinationURL.appending(path: "exports", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)

        let manifestURL = destinationURL.appending(path: "manifest.json")
        let auditURL = destinationURL.appending(path: "audit.ndjson")
        try encoder.encode(project).write(to: manifestURL)

        let auditLines = try auditEvents
            .map { try String(decoding: encoder.encode($0), as: UTF8.self) }
            .joined(separator: "\n")
        try Data(auditLines.utf8).write(to: auditURL)

        if let sourceXLSXURL {
            let targetURL = sourceDirectory.appending(path: sourceXLSXURL.lastPathComponent)
            try fileManager.copyItem(at: sourceXLSXURL, to: targetURL)
        }
    }

    func load(from packageURL: URL) throws -> ProjectPackage {
        let fileManager = FileManager.default
        let manifestURL = packageURL.appending(path: "manifest.json")
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw ProjectPackageStoreError.missingManifest
        }

        let manifestData = try Data(contentsOf: manifestURL)
        let project = try decoder.decode(DubProject.self, from: manifestData)

        let auditURL = packageURL.appending(path: "audit.ndjson")
        let auditEvents: [AuditEvent]
        if fileManager.fileExists(atPath: auditURL.path) {
            let raw = try String(contentsOf: auditURL)
            auditEvents = try raw
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { !$0.isEmpty }
                .map { try decoder.decode(AuditEvent.self, from: Data($0.utf8)) }
        } else {
            auditEvents = []
        }

        let sourceDirectory = packageURL.appending(path: "source", directoryHint: .isDirectory)
        let sourceXLSXURL = try? fileManager.contentsOfDirectory(
            at: sourceDirectory,
            includingPropertiesForKeys: nil
        ).first(where: { $0.pathExtension.lowercased() == "xlsx" })

        return ProjectPackage(project: project, auditEvents: auditEvents, sourceXLSXURL: sourceXLSXURL)
    }
}
