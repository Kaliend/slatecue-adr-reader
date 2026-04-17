import SwiftUI

struct PreparationView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var localization: LocalizationController
    @State private var newActorName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                TextField(localization.text("preparation.new_actor_placeholder"), text: $newActorName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)

                Button(localization.text("common.add")) {
                    appModel.createActor(named: newActorName)
                    newActorName = ""
                }
                .disabled(newActorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }

            header

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(appModel.characterSummaries) { summary in
                        HStack(alignment: .center, spacing: 12) {
                            Text(summary.character.name)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Picker(
                                localization.text("preparation.actor"),
                                selection: Binding(
                                    get: { summary.character.assignedActorID },
                                    set: { appModel.assignActor($0, to: summary.character.id) }
                                )
                            ) {
                                Text(localization.text("common.unassigned")).tag(Optional<UUID>.none)
                                ForEach(appModel.actors) { actor in
                                    Text(actor.displayName).tag(Optional(actor.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 180)

                            metric("\(summary.cueCount)", width: 70)
                            metric("\(summary.wordCount)", width: 80)
                            metric("\(summary.plannedTakes)", width: 80)
                            metric("\(summary.recordedCueCount)", width: 90)
                            metric("\(summary.remainingCueCount)", width: 90)
                            metric(String(format: "%.0f %%", summary.recordedRatio * 100), width: 80)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(20)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(localization.text("preparation.character"))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(localization.text("preparation.actor"))
                .frame(width: 180, alignment: .leading)
            Text(localization.text("preparation.cues"))
                .frame(width: 70)
            Text(localization.text("preparation.words"))
                .frame(width: 80)
            Text(localization.text("preparation.takes_div8"))
                .frame(width: 80)
            Text(localization.text("preparation.recorded"))
                .frame(width: 90)
            Text(localization.text("preparation.remaining"))
                .frame(width: 90)
            Text("%")
                .frame(width: 80)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
    }

    private func metric(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .frame(width: width, alignment: .trailing)
            .monospacedDigit()
    }
}
