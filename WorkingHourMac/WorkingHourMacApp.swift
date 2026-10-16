import SwiftUI

@main
struct WorkingHourMacApp: App {
    @State private var languageSettings = MacLanguageSettings.shared
    private let modelContainer = SharedModelContainer.shared.container

    var body: some Scene {
        WindowGroup {
            MacAttendanceDashboardView()
                .frame(minWidth: 760, minHeight: 520)
                .environment(\.locale, languageSettings.locale)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 920, height: 620)

        Settings {
            MacLanguageSettingsView()
        }
    }
}
