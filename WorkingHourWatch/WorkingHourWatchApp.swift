import SwiftUI

@main
struct WorkingHourWatchApp: App {
    private let modelContainer = SharedModelContainer.shared.container

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                if let warning = SharedModelContainer.shared.lastInitializationErrorDescription {
                    Label("当前使用本机存储", systemImage: "externaldrive.badge.exclamationmark")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.orange.opacity(0.12))
                        .accessibilityHint(warning)
                }

                AttendanceDashboardView(displayStyle: .compact)
            }
        }
        .modelContainer(modelContainer)
    }
}
