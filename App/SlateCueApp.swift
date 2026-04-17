import AppKit
import SwiftUI

@main
struct SlateCueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var localization: LocalizationController
    @StateObject private var appModel: AppModel

    init() {
        let localization = LocalizationController()
        _localization = StateObject(wrappedValue: localization)
        _appModel = StateObject(wrappedValue: AppModel(localization: localization))
    }

    var body: some Scene {
        WindowGroup(localization.text("app.name")) {
            ControlWindowView()
                .environmentObject(appModel)
                .environmentObject(localization)
                .frame(minWidth: 1100, minHeight: 760)
        }
        .defaultSize(width: 1280, height: 840)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(localization.text("command.import_xlsx")) {
                    appModel.importXLSXInteractive()
                }
                .keyboardShortcut("i", modifiers: [.command])

                Button(localization.text("command.open_project")) {
                    appModel.openProjectInteractive()
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button(localization.text("command.save_project")) {
                    appModel.saveProjectInteractive()
                }
                .keyboardShortcut("s", modifiers: [.command])

                Button(localization.text("command.save_project_as")) {
                    appModel.saveProjectAsInteractive()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button(localization.text("command.export_xlsx")) {
                    appModel.exportStatusInteractive()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }

        Window(localization.text("window.display"), id: "display-window") {
            DisplayWindowView()
                .environmentObject(appModel)
                .environmentObject(localization)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1280, height: 820)

        Settings {
            SettingsView()
                .environmentObject(localization)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let icon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = icon
            return
        }

        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL) else {
            return
        }

        NSApplication.shared.applicationIconImage = icon
    }
}
