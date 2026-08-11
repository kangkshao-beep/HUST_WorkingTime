import AttendanceKit
import SwiftData
import SwiftUI

enum AttendanceDashboardDisplayStyle {
    case regular
    case compact
}

struct AttendanceDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = AttendanceStore.shared

    let displayStyle: AttendanceDashboardDisplayStyle

    init(displayStyle: AttendanceDashboardDisplayStyle = .regular) {
        self.displayStyle = displayStyle
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: displayStyle == .compact ? 12 : 16) {
                    AttendanceDashboardTodayCard(
                        store: store,
                        now: context.date,
                        displayStyle: displayStyle
                    )

                    AttendanceDashboardMonthCard(
                        progress: store.monthProgress(containing: context.date, now: context.date),
                        displayStyle: displayStyle
                    )

                    if let message = store.lastErrorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(.orange.opacity(0.12))
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
                .padding(displayStyle == .compact ? 12 : 20)
            }
        }
        .task {
            store.configure(modelContext: modelContext)
        }
        .onAppear {
            store.configure(modelContext: modelContext)
        }
    }
}

private struct AttendanceDashboardTodayCard: View {
    let store: AttendanceStore
    let now: Date
    let displayStyle: AttendanceDashboardDisplayStyle

    var body: some View {
        let record = store.todayRecord(now: now)
        let status = store.status(for: record, now: now)

        VStack(alignment: .leading, spacing: displayStyle == .compact ? 10 : 14) {
            Text(now, format: .dateTime.year().month().day().weekday(.wide))
                .font(.headline)
                .foregroundStyle(.secondary)

            switch status {
            case .weekend:
                Label("今天休息", systemImage: "moon.zzz.fill")
                    .font(displayStyle == .compact ? .headline.weight(.bold) : .title.weight(.bold))
            case .notClockedIn:
                Text("今天是工作日")
                    .font(displayStyle == .compact ? .headline.weight(.bold) : .title.weight(.bold))
                Button {
                    store.clockInNow()
                } label: {
                    Label("现在打卡", systemImage: "figure.walk.arrival")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            case .working, .targetReached, .clockedOutEarly, .completed:
                if let record {
                    AttendanceDashboardCountdown(
                        store: store,
                        record: record,
                        now: now,
                        status: status,
                        displayStyle: displayStyle
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(displayStyle == .compact ? 12 : 16)
        .background(.gray.opacity(0.12))
        .clipShape(.rect(cornerRadius: 8))
    }
}

private struct AttendanceDashboardCountdown: View {
    let store: AttendanceStore
    let record: AttendanceRecord
    let now: Date
    let status: AttendanceStatus
    let displayStyle: AttendanceDashboardDisplayStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch status {
            case .working:
                Text(record.targetEndAt, style: .timer)
                    .font(.system(size: displayStyle == .compact ? 34 : 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                Text("距离 8 小时目标")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .targetReached:
                Label("8 小时已完成", systemImage: "checkmark.circle.fill")
                    .font(displayStyle == .compact ? .headline.weight(.bold) : .title2.weight(.bold))
                    .foregroundStyle(.green)
            case .clockedOutEarly:
                Label("已提前结束", systemImage: "exclamationmark.circle.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.orange)
            case .completed:
                Label("今天已完成", systemImage: "checkmark.circle.fill")
                    .font(displayStyle == .compact ? .headline.weight(.bold) : .title2.weight(.bold))
                    .foregroundStyle(.green)
            case .weekend, .notClockedIn:
                EmptyView()
            }

            VStack(alignment: .leading, spacing: 4) {
                Label(record.clockInAt.formatted(date: .omitted, time: .shortened), systemImage: "figure.walk.arrival")
                Label(record.targetEndAt.formatted(date: .omitted, time: .shortened), systemImage: "door.right.hand.open")
                if let actualClockOutAt = record.actualClockOutAt {
                    Label(actualClockOutAt.formatted(date: .omitted, time: .shortened), systemImage: "figure.walk.departure")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ProgressView(value: store.dailyProgress(for: record, now: now))

            if record.actualClockOutAt == nil {
                Button {
                    store.clockOut(record: record)
                } label: {
                    Label("结束今天工作", systemImage: "figure.walk.departure")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct AttendanceDashboardMonthCard: View {
    let progress: MonthProgress
    let displayStyle: AttendanceDashboardDisplayStyle

    var body: some View {
        VStack(alignment: .leading, spacing: displayStyle == .compact ? 8 : 10) {
            HStack {
                Text("本月达标进度")
                    .font(.headline)
                Spacer()
                Text(progress.passed ? String(localized: "已达标") : String(localized: "未达标"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(progress.passed ? .green : .orange)
            }

            ProgressView(value: progress.progressToRequirement)

            if displayStyle == .compact {
                Text("\(progress.validAttendanceDays) / \(progress.requiredDays) 天")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                    GridRow { Text("有效打卡"); Text("\(progress.validAttendanceDays) 天") }
                    GridRow { Text("80% 要求"); Text("\(progress.requiredDays) 天") }
                    GridRow { Text("还需"); Text("\(progress.remainingNeeded) 天") }
                    GridRow { Text("当月工作日"); Text("\(progress.totalWorkdays) 天") }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(displayStyle == .compact ? 12 : 16)
        .background(.gray.opacity(0.12))
        .clipShape(.rect(cornerRadius: 8))
    }
}
