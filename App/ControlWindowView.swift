import SwiftUI

struct ControlWindowView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var localization: LocalizationController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if appModel.project == nil {
                WelcomeView()
            } else {
                NavigationSplitView {
                    List(
                        ControlSection.allCases,
                        selection: Binding(
                            get: { appModel.activeSection },
                            set: { appModel.activeSection = $0 ?? .preparation }
                        )
                    ) { section in
                        Label(section.title(localization: localization), systemImage: section.systemImage)
                            .tag(section)
                    }
                    .navigationSplitViewColumnWidth(min: 180, ideal: 220)
                } detail: {
                    switch appModel.activeSection {
                    case .preparation:
                        PreparationView()
                    case .recording:
                        RecordingView()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(localization.text("toolbar.import")) {
                    appModel.importXLSXInteractive()
                }

                Button(localization.text("toolbar.open")) {
                    appModel.openProjectInteractive()
                }

                Button(localization.text("toolbar.save")) {
                    appModel.saveProjectInteractive()
                }
                .disabled(appModel.project == nil)

                Button(localization.text("toolbar.display")) {
                    openWindow(id: "display-window")
                }
                .disabled(appModel.project == nil)

                Button(localization.text("toolbar.export")) {
                    appModel.exportStatusInteractive()
                }
                .disabled(appModel.project == nil)
            }
        }
        .alert(
            localization.text("alert.error_title"),
            isPresented: Binding(
                get: { appModel.alertMessage != nil },
                set: { if !$0 { appModel.alertMessage = nil } }
            ),
            actions: {
                Button(localization.text("common.ok"), role: .cancel) {
                    appModel.alertMessage = nil
                }
            },
            message: {
                Text(appModel.alertMessage ?? "")
            }
        )
        .overlay(alignment: .bottomTrailing) {
            if appModel.isBusy {
                ProgressView()
                    .controlSize(.large)
                    .padding()
            }
        }
    }
}
