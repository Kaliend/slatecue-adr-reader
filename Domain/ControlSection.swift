import Foundation

enum ControlSection: String, CaseIterable, Identifiable, Sendable {
    case preparation
    case recording

    var id: String { rawValue }

    @MainActor
    func title(localization: LocalizationController) -> String {
        switch self {
        case .preparation:
            return localization.text("section.preparation")
        case .recording:
            return localization.text("section.recording")
        }
    }

    var systemImage: String {
        switch self {
        case .preparation:
            return "person.3.sequence"
        case .recording:
            return "waveform.and.mic"
        }
    }
}
