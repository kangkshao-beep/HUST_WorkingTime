import SwiftUI

@main
struct WorkingHourMacApp: App {
    private let modelContainer = SharedModelContainer.shared.container

    var body: some Scene {
        WindowGroup {
            MacAttendanceDashboardView()
                .frame(minWidth: 760, minHeight: 520)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 920, height: 620)
    }
}
