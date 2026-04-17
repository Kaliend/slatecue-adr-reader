import SwiftUI

struct DisplayWindowView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var localization: LocalizationController

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if let context = appModel.displayContext {
                    let rowCount = context.previous.count + context.next.count + 1
                    let metrics = DisplayLayoutMetrics(
                        containerSize: proxy.size,
                        rowCount: rowCount
                    )

                    VStack(spacing: metrics.rowSpacing) {
                        ForEach(Array(context.previous.enumerated()), id: \.element.id) { index, cue in
                            let distance = context.previous.count - index
                            displayCueCard(
                                cue: cue,
                                emphasis: DisplayCueEmphasis(distance: distance),
                                metrics: metrics
                            )
                        }

                        displayCueCard(
                            cue: context.current,
                            emphasis: .current,
                            metrics: metrics
                        )

                        ForEach(Array(context.next.enumerated()), id: \.element.id) { index, cue in
                            let distance = index + 1
                            displayCueCard(
                                cue: cue,
                                emphasis: DisplayCueEmphasis(distance: distance),
                                metrics: metrics
                            )
                        }
                    }
                    .padding(metrics.outerPadding)
                    .frame(
                        maxWidth: min(
                            max(proxy.size.width - (metrics.outerPadding * 2), 0),
                            1400
                        ),
                        maxHeight: .infinity,
                        alignment: .center
                    )
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        alignment: .center
                    )
                } else {
                    Text(localization.text("display.no_selected_cue"))
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    private func displayCueCard(
        cue: Cue,
        emphasis: DisplayCueEmphasis,
        metrics: DisplayLayoutMetrics
    ) -> some View {
        ZStack(alignment: .top) {
            Text(displayText(for: cue))
                .font(metrics.textFont(for: emphasis))
                .multilineTextAlignment(.center)
                .foregroundStyle(textColor(for: cue, emphasis: emphasis))
                .lineLimit(metrics.lineLimit(for: emphasis))
                .minimumScaleFactor(metrics.minimumScaleFactor(for: emphasis))
                .padding(.top, metrics.textTopInset(for: emphasis))
                .padding(.horizontal, metrics.textHorizontalPadding(for: emphasis))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            cueMetaRow(
                cue: cue,
                emphasis: emphasis,
                metrics: metrics
            )
            .padding(.top, metrics.metaTopInset(for: emphasis))
            .padding(.horizontal, metrics.cardHorizontalPadding(for: emphasis))
        }
        .frame(maxWidth: .infinity)
        .frame(height: metrics.rowHeight(for: emphasis))
        .background(
            backgroundStyle(for: cue, emphasis: emphasis),
            in: RoundedRectangle(cornerRadius: metrics.cornerRadius(for: emphasis))
        )
    }

    private func cueMetaRow(
        cue: Cue,
        emphasis: DisplayCueEmphasis,
        metrics: DisplayLayoutMetrics
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(appModel.characterName(for: cue.characterID))
                .font(metrics.characterFont(for: emphasis))
                .foregroundStyle(metaColor(for: cue, emphasis: emphasis))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(appModel.displayTimecode(cue.inTimecode))
                .font(metrics.timecodeFont(for: emphasis))
                .foregroundStyle(metaColor(for: cue, emphasis: emphasis))
                .frame(width: metrics.timecodeSlotWidth, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .monospacedDigit()
    }

    private func displayText(for cue: Cue) -> String {
        cue.dialogue.isEmpty ? localization.text("common.empty_cue") : cue.dialogue
    }

    private func textColor(for cue: Cue, emphasis: DisplayCueEmphasis) -> Color {
        appModel.isCueMarkedForActiveActor(cue) ? emphasis.actorTextColor : emphasis.defaultTextColor
    }

    private func metaColor(for cue: Cue, emphasis: DisplayCueEmphasis) -> Color {
        appModel.isCueMarkedForActiveActor(cue) ? emphasis.actorMetaColor : emphasis.defaultMetaColor
    }

    private func backgroundStyle(for cue: Cue, emphasis: DisplayCueEmphasis) -> Color {
        appModel.isCueMarkedForActiveActor(cue) ? emphasis.actorBackgroundColor : emphasis.defaultBackgroundColor
    }
}

private struct DisplayLayoutMetrics {
    let outerPadding: CGFloat
    let rowSpacing: CGFloat
    let timecodeSlotWidth: CGFloat

    private let containerSize: CGSize
    private let rowCount: Int
    private let currentRowHeight: CGFloat
    private let contextRowHeight: CGFloat

    init(containerSize: CGSize, rowCount: Int) {
        self.containerSize = containerSize
        self.rowCount = max(rowCount, 1)

        let width = max(containerSize.width, 1)
        let height = max(containerSize.height, 1)

        outerPadding = Self.clamp(height * 0.018, min: 8, max: 26)

        let baseSpacing = Self.clamp(height * 0.008, min: 4, max: 12)
        let densityPenalty = CGFloat(max(self.rowCount - 7, 0)) * 0.8
        rowSpacing = max(2, baseSpacing - densityPenalty)

        let currentWeight: CGFloat
        switch self.rowCount {
        case ...5:
            currentWeight = 1.85
        case ...9:
            currentWeight = 1.60
        case ...13:
            currentWeight = 1.42
        default:
            currentWeight = 1.30
        }

        let totalSpacing = rowSpacing * CGFloat(max(self.rowCount - 1, 0))
        let availableHeight = max(120, height - (outerPadding * 2) - totalSpacing)
        let baseContextHeight = availableHeight / (CGFloat(max(self.rowCount - 1, 0)) + currentWeight)

        contextRowHeight = baseContextHeight
        currentRowHeight = baseContextHeight * currentWeight
        timecodeSlotWidth = Self.clamp(width * 0.10, min: 92, max: 176)
    }

    func rowHeight(for emphasis: DisplayCueEmphasis) -> CGFloat {
        switch emphasis {
        case .current:
            return currentRowHeight
        case .near, .far:
            return contextRowHeight
        }
    }

    func textFont(for emphasis: DisplayCueEmphasis) -> Font {
        let height = rowHeight(for: emphasis)

        switch emphasis {
        case .current:
            return .system(
                size: Self.clamp(height * 0.40, min: 24, max: 62),
                weight: .bold,
                design: .rounded
            )
        case .near:
            return .system(
                size: Self.clamp(height * 0.34, min: 16, max: 34),
                weight: .medium,
                design: .rounded
            )
        case .far:
            return .system(
                size: Self.clamp(height * 0.31, min: 14, max: 28),
                weight: .medium,
                design: .rounded
            )
        }
    }

    func characterFont(for emphasis: DisplayCueEmphasis) -> Font {
        let height = rowHeight(for: emphasis)

        switch emphasis {
        case .current:
            return .system(
                size: Self.clamp(height * 0.18, min: 13, max: 24),
                weight: .semibold
            )
        case .near, .far:
            return .system(
                size: Self.clamp(height * 0.18, min: 11, max: 18),
                weight: .semibold
            )
        }
    }

    func timecodeFont(for emphasis: DisplayCueEmphasis) -> Font {
        let height = rowHeight(for: emphasis)

        switch emphasis {
        case .current:
            return .system(
                size: Self.clamp(height * 0.16, min: 13, max: 22),
                weight: .medium,
                design: .monospaced
            )
        case .near, .far:
            return .system(
                size: Self.clamp(height * 0.16, min: 10, max: 16),
                weight: .medium,
                design: .monospaced
            )
        }
    }

    func lineLimit(for emphasis: DisplayCueEmphasis) -> Int {
        switch emphasis {
        case .current:
            return currentRowHeight > 92 ? 2 : 1
        case .near, .far:
            return 1
        }
    }

    func minimumScaleFactor(for emphasis: DisplayCueEmphasis) -> CGFloat {
        switch emphasis {
        case .current:
            return 0.52
        case .near, .far:
            return 0.44
        }
    }

    func textHorizontalPadding(for emphasis: DisplayCueEmphasis) -> CGFloat {
        let width = containerSize.width

        switch emphasis {
        case .current:
            return Self.clamp(width * 0.04, min: 12, max: 80)
        case .near, .far:
            return Self.clamp(width * 0.028, min: 8, max: 56)
        }
    }

    func textTopInset(for emphasis: DisplayCueEmphasis) -> CGFloat {
        rowHeight(for: emphasis) * 0.18
    }

    func metaTopInset(for emphasis: DisplayCueEmphasis) -> CGFloat {
        Self.clamp(rowHeight(for: emphasis) * 0.10, min: 4, max: 14)
    }

    func cardHorizontalPadding(for emphasis: DisplayCueEmphasis) -> CGFloat {
        let width = containerSize.width

        switch emphasis {
        case .current:
            return Self.clamp(width * 0.012, min: 8, max: 28)
        case .near, .far:
            return Self.clamp(width * 0.010, min: 6, max: 22)
        }
    }

    func cornerRadius(for emphasis: DisplayCueEmphasis) -> CGFloat {
        switch emphasis {
        case .current:
            return Self.clamp(rowHeight(for: emphasis) * 0.20, min: 14, max: 30)
        case .near, .far:
            return Self.clamp(rowHeight(for: emphasis) * 0.18, min: 10, max: 22)
        }
    }

    private static func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}

private enum DisplayCueEmphasis {
    case current
    case near
    case far

    init(distance: Int) {
        switch distance {
        case 1:
            self = .near
        default:
            self = .far
        }
    }

    var defaultTextColor: Color {
        switch self {
        case .current:
            return .white
        case .near:
            return .white.opacity(0.72)
        case .far:
            return .white.opacity(0.54)
        }
    }

    var actorTextColor: Color {
        switch self {
        case .current:
            return Color(red: 1.0, green: 0.88, blue: 0.55)
        case .near:
            return Color(red: 0.98, green: 0.82, blue: 0.42).opacity(0.86)
        case .far:
            return Color(red: 0.95, green: 0.76, blue: 0.36).opacity(0.72)
        }
    }

    var defaultMetaColor: Color {
        switch self {
        case .current:
            return .white.opacity(0.7)
        case .near:
            return .white.opacity(0.46)
        case .far:
            return .white.opacity(0.30)
        }
    }

    var actorMetaColor: Color {
        switch self {
        case .current:
            return Color(red: 1.0, green: 0.85, blue: 0.42).opacity(0.88)
        case .near:
            return Color(red: 0.98, green: 0.78, blue: 0.34).opacity(0.72)
        case .far:
            return Color(red: 0.95, green: 0.74, blue: 0.30).opacity(0.58)
        }
    }

    var defaultBackgroundColor: Color {
        switch self {
        case .current:
            return .white.opacity(0.05)
        case .near:
            return .white.opacity(0.05)
        case .far:
            return .white.opacity(0.03)
        }
    }

    var actorBackgroundColor: Color {
        switch self {
        case .current:
            return Color.orange.opacity(0.14)
        case .near:
            return Color.orange.opacity(0.10)
        case .far:
            return Color.orange.opacity(0.07)
        }
    }
}
