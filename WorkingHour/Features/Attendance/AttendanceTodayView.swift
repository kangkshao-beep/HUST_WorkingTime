import AttendanceKit
import SwiftData
import SwiftUI

struct AttendanceTodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = AttendanceStore.shared
    @State private var showingManualClockIn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TodayStatusCard(store: store, showingManualClockIn: $showingManualClockIn)
                    MonthProgressCard(progress: store.monthProgress())
                    if let message = store.lastErrorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.orange.opacity(0.12))
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
                .padding()
            }
            .navigationTitle("今天")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
                store.configure(modelContext: modelContext)
            }
            .onAppear {
                store.configure(modelContext: modelContext)
            }
            .sheet(isPresented: $showingManualClockIn) {
                ManualClockInSheet(store: store)
            }
        }
    }
}

private struct TodayStatusCard: View {
    let store: AttendanceStore
    @Binding var showingManualClockIn: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let record = store.todayRecord(now: now)
            let status = store.status(for: record, now: now)
            VStack(alignment: .leading, spacing: 14) {
                Text(now, format: .dateTime.year().month().day().weekday(.wide))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                switch status {
                case .weekend:
                    Label("今天休息", systemImage: "moon.zzz.fill")
                        .font(.largeTitle.weight(.bold))
                    Text("周末无需打卡，本月进度仍会保持更新。")
                        .foregroundStyle(.secondary)
                case .notClockedIn:
                    Text("今天是工作日")
                        .font(.title.weight(.bold))
                    Button {
                        store.clockInNow()
                    } label: {
                        Label("现在打卡", systemImage: "figure.walk.arrival")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityLabel("现在打卡")
                    .accessibilityHint("使用当前时间创建今天的打卡记录")

                    Button {
                        showingManualClockIn = true
                    } label: {
                        Label("选择打卡时间", systemImage: "clock.badge")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                case .working, .targetReached, .clockedOutEarly, .completed:
                    if let record {
                        AttendanceCountdownView(store: store, record: record, now: now, status: status, showingManualClockIn: $showingManualClockIn)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.groupedBackground)
            .clipShape(.rect(cornerRadius: 8))
        }
    }
}

private struct AttendanceCountdownView: View {
    let store: AttendanceStore
    let record: AttendanceRecord
    let now: Date
    let status: AttendanceStatus
    @Binding var showingManualClockIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch status {
            case .working:
                Text("距离下班")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(record.targetEndAt, style: .timer)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
            case .targetReached:
                Label("今天 8 小时已完成", systemImage: "checkmark.circle.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.green)
                Text("可以下班了")
                    .font(.headline)
            case .clockedOutEarly:
                Label("已提前结束今天工作", systemImage: "exclamationmark.circle.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.orange)
            case .completed:
                Label("今天已完成", systemImage: "checkmark.circle.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.green)
            case .weekend, .notClockedIn:
                EmptyView()
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("上班：\(record.clockInAt.formatted(date: .omitted, time: .shortened))", systemImage: "figure.walk.arrival")
                Label("预计下班：\(record.targetEndAt.formatted(date: .omitted, time: .shortened))", systemImage: "door.right.hand.open")
                if let actualClockOutAt = record.actualClockOutAt {
                    Label("实际下班：\(actualClockOutAt.formatted(date: .omitted, time: .shortened))", systemImage: "figure.walk.departure")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            ProgressView(value: store.dailyProgress(for: record, now: now)) {
                Text("8 小时进度")
            } currentValueLabel: {
                Text(store.dailyProgress(for: record, now: now), format: .percent.precision(.fractionLength(0)))
            }

            HStack {
                Button {
                    store.clockOut(record: record)
                } label: {
                    Label("结束今天工作", systemImage: "figure.walk.departure")
                }
                .buttonStyle(.borderedProminent)
                .disabled(record.actualClockOutAt != nil)

                Button {
                    showingManualClockIn = true
                } label: {
                    Label("修改打卡时间", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct MonthProgressCard: View {
    let progress: MonthProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("本月达标进度")
                    .font(.headline)
                Spacer()
                Text(progress.passed ? "已达标" : "未达标")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(progress.passed ? .green : .orange)
            }
            ProgressView(value: progress.progressToRequirement)
            HStack {
                VStack(alignment: .leading) {
                    Text("有效打卡")
                    Text("\(progress.validAttendanceDays) 天")
                        .font(.title3.weight(.bold))
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("80% 要求")
                    Text("\(progress.requiredDays) 天")
                        .font(.title3.weight(.bold))
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("还需")
                    Text("\(progress.remainingNeeded) 天")
                        .font(.title3.weight(.bold))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.groupedBackground)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityLabel("本月已打卡 \(progress.validAttendanceDays) 天，需要 \(progress.requiredDays) 天")
    }
}

private struct ManualClockInSheet: View {
    @Environment(\.dismiss) private var dismiss
    let store: AttendanceStore
    @State private var selectedTime = Date()
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "打卡时间",
                    selection: $selectedTime,
                    in: store.workdayCalendar.startOfDay(for: Date())...Date(),
                    displayedComponents: [.hourAndMinute]
                )
                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle("选择打卡时间")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard selectedTime <= Date() else {
                            validationMessage = "不能选择未来时间。"
                            return
                        }
                        store.clockIn(at: selectedTime, isManual: true)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
