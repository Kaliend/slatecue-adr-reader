import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var localization: LocalizationController

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(localization.text("app.name"))
                    .font(.largeTitle.bold())

                Text(localization.text("app.subtitle"))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                Button(localization.text("command.import_xlsx")) {
                    appModel.importXLSXInteractive()
                }
                .buttonStyle(.borderedProminent)

                Button(localization.text("command.open_project")) {
                    appModel.openProjectInteractive()
                }
                .buttonStyle(.bordered)

                Button(localization.text("welcome.load_demo")) {
                    appModel.loadDemoProject()
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
