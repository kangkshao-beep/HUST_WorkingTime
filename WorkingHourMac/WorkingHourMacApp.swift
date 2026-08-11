import SwiftUI

@main
struct WorkingHourMacApp: App {
    private let modelContainer = SharedModelContainer.shared.container

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                if let warning = SharedModelContainer.shared.lastInitializationErrorDescription {
                    Text(warning)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.orange.opacity(0.12))
                }

                AttendanceDashboardView(displayStyle: .regular)
            }
            .frame(minWidth: 480, minHeight: 620)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 560, height: 720)
    }
}
