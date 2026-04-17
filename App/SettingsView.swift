import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var localization: LocalizationController

    var body: some View {
        Form {
            Picker(
                localization.text("settings.language"),
                selection: $localization.language
            ) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeDisplayName).tag(language)
                }
            }
            .pickerStyle(.radioGroup)

            Text(localization.text("settings.language_help"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420)
    }
}
