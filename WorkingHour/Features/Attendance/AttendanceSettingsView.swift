import SwiftData
import SwiftUI

struct AttendanceSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = AttendanceStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section("当前规则") {
                    LabeledContent("每日目标", value: "8 小时")
                    LabeledContent("月度要求", value: "80% 工作日")
                    LabeledContent("工作日", value: "周一至周五")
                }
                Section("同步与存储") {
                    if let error = SharedModelContainer.shared.lastInitializationErrorDescription {
                        LabeledContent("SwiftData", value: "本地 fallback")
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    } else {
                        LabeledContent("SwiftData", value: "可用")
                    }
                    LabeledContent("App Group", value: WidgetSnapshotStore.appGroupIdentifier)
                    Text("iCloud 和 App Group 标识符仍使用当前工程配置。请按 MANUAL_SETUP.md 替换为自己的 Team 与容器。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("跨设备") {
                    Label("macOS App 与桌面 Widget", systemImage: "macbook")
                    Label("Apple Watch 与表盘组件", systemImage: "applewatch")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AttendanceScreenBackground())
            .navigationTitle("设置")
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task { store.configure(modelContext: modelContext) }
        }
    }
}
