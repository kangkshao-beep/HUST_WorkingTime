import AttendanceKit
import SwiftData
import SwiftUI

struct AttendanceHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = AttendanceStore.shared
    @State private var selectedRecord: AttendanceRecord?
    @State private var recordToDelete: AttendanceRecord?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentUnavailableView("暂无打卡记录", systemImage: "calendar.badge.clock")
                } else {
                    List {
                        ForEach(store.records, id: \.id) { record in
                            Button {
                                selectedRecord = record
                            } label: {
                                HistoryRecordRow(record: record)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    recordToDelete = record
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AttendanceScreenBackground())
                }
            }
            .background(AttendanceScreenBackground())
            .navigationTitle("历史")
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task { store.configure(modelContext: modelContext) }
            .onAppear { store.configure(modelContext: modelContext) }
            .sheet(item: $selectedRecord) { record in
                AttendanceRecordEditor(store: store, record: record)
            }
            .confirmationDialog("删除这条打卡记录？", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    if let recordToDelete {
                        store.delete(record: recordToDelete)
                    }
                    recordToDelete = nil
                    showingDeleteConfirmation = false
                }
                Button("取消", role: .cancel) {
                    recordToDelete = nil
                    showingDeleteConfirmation = false
                }
            }
        }
    }
}

private struct HistoryRecordRow: View {
    let record: AttendanceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.clockInAt, format: .dateTime.year().month().day().weekday(.wide))
                    .font(.headline)
                Spacer()
                if record.isManualClockIn {
                    Label("手动", systemImage: "pencil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 12) {
                Label(record.clockInAt.formatted(date: .omitted, time: .shortened), systemImage: "figure.walk.arrival")
                Label(record.targetEndAt.formatted(date: .omitted, time: .shortened), systemImage: "door.right.hand.open")
                if let actualClockOutAt = record.actualClockOutAt {
                    Label(actualClockOutAt.formatted(date: .omitted, time: .shortened), systemImage: "figure.walk.departure")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text("来源：\(record.sourceDevice)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AttendanceRecordEditor: View {
    @Environment(\.dismiss) private var dismiss
    let store: AttendanceStore
    let record: AttendanceRecord

    @State private var clockInAt: Date
    @State private var clockOutAt: Date
    @State private var hasClockOut: Bool
    @State private var message: String?

    init(store: AttendanceStore, record: AttendanceRecord) {
        self.store = store
        self.record = record
        _clockInAt = State(initialValue: record.clockInAt)
        _clockOutAt = State(initialValue: record.actualClockOutAt ?? Date())
        _hasClockOut = State(initialValue: record.actualClockOutAt != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("上班时间", selection: $clockInAt, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                Toggle("记录实际下班", isOn: $hasClockOut)
                if hasClockOut {
                    DatePicker("实际下班", selection: $clockOutAt, in: clockInAt...Date.distantFuture, displayedComponents: [.date, .hourAndMinute])
                }
                if let message {
                    Text(message)
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle("编辑打卡")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if hasClockOut && clockOutAt < clockInAt {
                            message = "下班时间不能早于上班时间。"
                            return
                        }
                        store.update(record: record, clockInAt: clockInAt, actualClockOutAt: hasClockOut ? clockOutAt : nil)
                        dismiss()
                    }
                }
            }
        }
    }
}
