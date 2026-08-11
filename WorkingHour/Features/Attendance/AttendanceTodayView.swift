import AttendanceKit
import SwiftData
import SwiftUI

struct AttendanceTodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = AttendanceStore.shared
    @State private var showingManualClockIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                AttendanceScreenBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        AttendanceTipBanner(text: "稳稳完成今天，也是在靠近长期目标。")
                        TodayStatusPanel(
                            store: store,
                            showingManualClockIn: $showingManualClockIn
                        )
                        if let record = store.todayRecord() {
                            CantoneseLyricSharePanel(record: record)
                        }
                        TodayMetricsPanel(store: store)

                        if let message = store.lastErrorMessage {
                            AttendancePanel {
                                Label(message, systemImage: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("工时倒计时")
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                store.configure(modelContext: modelContext)
            }
            .onAppear {
                store.configure(modelContext: modelContext)
            }
            .sheet(isPresented: $showingManualClockIn) {
                ManualClockInSheet(store: store, existingRecord: store.todayRecord())
            }
        }
    }
}

private struct TodayStatusPanel: View {
    let store: AttendanceStore
    @Binding var showingManualClockIn: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let record = store.todayRecord(now: now)
            let status = store.status(for: record, now: now)

            AttendancePanel {
                VStack(spacing: 20) {
                    Text(now, format: .dateTime.month().day().weekday(.wide))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AttendanceTheme.secondaryInk)
                        .frame(maxWidth: .infinity)

                    switch status {
                    case .weekend:
                        WeekendState()
                    case .notClockedIn:
                        NotClockedInState(showingManualClockIn: $showingManualClockIn) {
                            store.clockInNow()
                        }
                    case .working, .targetReached, .clockedOutEarly, .completed:
                        if let record {
                            AttendanceCountdownContent(
                                store: store,
                                record: record,
                                now: now,
                                status: status,
                                showingManualClockIn: $showingManualClockIn
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 330, alignment: .top)
            }
        }
    }
}

private struct WeekendState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 44))
                .foregroundStyle(AttendanceTheme.accent)
            Text("今天休息")
                .font(.title.bold())
                .foregroundStyle(AttendanceTheme.ink)
            Text("周末不会计入本月出勤要求")
                .font(.subheadline)
                .foregroundStyle(AttendanceTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct NotClockedInState: View {
    @Binding var showingManualClockIn: Bool
    let clockInNow: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "figure.walk.arrival")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AttendanceTheme.accent)
                .frame(width: 78, height: 78)
                .background(AttendanceTheme.accent.opacity(0.10))
                .clipShape(Circle())

            VStack(spacing: 6) {
                Text("准备开始今天")
                    .font(.title2.bold())
                    .foregroundStyle(AttendanceTheme.ink)
                Text("打卡后将自动计算 8 小时目标")
                    .font(.subheadline)
                    .foregroundStyle(AttendanceTheme.secondaryInk)
            }

            Button(action: clockInNow) {
                Label("现在打卡", systemImage: "play.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AttendanceTheme.accent)
            .controlSize(.large)

            Button {
                showingManualClockIn = true
            } label: {
                Label("选择打卡时间", systemImage: "clock.badge")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AttendanceTheme.accent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AttendanceCountdownContent: View {
    let store: AttendanceStore
    let record: AttendanceRecord
    let now: Date
    let status: AttendanceStatus
    @Binding var showingManualClockIn: Bool

    var body: some View {
        VStack(spacing: 18) {
            statusHeader

            if status == .working {
                Text(record.targetEndAt, style: .timer)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AttendanceTheme.accent)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }

            AttendanceProgressDots(progress: store.dailyProgress(for: record, now: now))

            HStack(spacing: 18) {
                TimeLabel(title: "上班", date: record.clockInAt, icon: "figure.walk.arrival")
                TimeLabel(title: "目标", date: record.targetEndAt, icon: "flag.checkered")
                if let actualClockOutAt = record.actualClockOutAt {
                    TimeLabel(title: "下班", date: actualClockOutAt, icon: "figure.walk.departure")
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                Button {
                    store.clockOut(record: record)
                } label: {
                    Label("结束工作", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AttendanceTheme.accent)
                .disabled(record.actualClockOutAt != nil)

                Button {
                    showingManualClockIn = true
                } label: {
                    Image(systemName: "pencil")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.bordered)
                .tint(AttendanceTheme.accent)
                .accessibilityLabel("修改打卡时间")
            }
        }
    }

    @ViewBuilder
    private var statusHeader: some View {
        switch status {
        case .working:
            Text("距离下班还有")
                .font(.headline)
                .foregroundStyle(AttendanceTheme.secondaryInk)
        case .targetReached:
            StatusLabel("8 小时已完成", icon: "checkmark.circle.fill", color: AttendanceTheme.mint)
        case .clockedOutEarly:
            StatusLabel("今天已提前结束", icon: "exclamationmark.circle.fill", color: .orange)
        case .completed:
            StatusLabel("今天已完成", icon: "checkmark.circle.fill", color: AttendanceTheme.mint)
        case .weekend, .notClockedIn:
            EmptyView()
        }
    }
}

private struct StatusLabel: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color

    init(_ title: LocalizedStringKey, icon: String, color: Color) {
        self.title = title
        self.icon = icon
        self.color = color
    }

    var body: some View {
        Label(title, systemImage: icon)
            .font(.title2.bold())
            .foregroundStyle(color)
    }
}

private struct TimeLabel: View {
    let title: LocalizedStringKey
    let date: Date
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Label(title, systemImage: icon)
                .labelStyle(.iconOnly)
                .foregroundStyle(AttendanceTheme.accent)
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(AttendanceTheme.secondaryInk)
        }
    }
}

private struct TodayMetricsPanel: View {
    let store: AttendanceStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let record = store.todayRecord(now: context.date)
            let progress = record.map { store.dailyProgress(for: $0, now: context.date) } ?? 0
            let month = store.monthProgress(containing: context.date, now: context.date)

            AttendancePanel {
                HStack(spacing: 8) {
                    TodayMetric(
                        icon: "chart.bar.fill",
                        color: AttendanceTheme.accent,
                        value: progress.formatted(.percent.precision(.fractionLength(0))),
                        label: "今日进度"
                    )
                    TodayMetricDivider()
                    TodayMetric(
                        icon: "clock.fill",
                        color: AttendanceTheme.accent,
                        value: workedDuration(record: record, now: context.date),
                        label: "已工作"
                    )
                    TodayMetricDivider()
                    TodayMetric(
                        icon: "calendar.badge.checkmark",
                        color: AttendanceTheme.mint,
                        value: "\(month.validAttendanceDays)/\(month.requiredDays)",
                        label: "月度出勤"
                    )
                }
            }
        }
    }

    private func workedDuration(record: AttendanceRecord?, now: Date) -> String {
        guard let record else { return "0:00" }
        let end = record.actualClockOutAt ?? now
        let totalMinutes = max(0, Int(end.timeIntervalSince(record.clockInAt) / 60))
        return String(format: "%d:%02d", totalMinutes / 60, totalMinutes % 60)
    }
}

private struct TodayMetric: View {
    let icon: String
    let color: Color
    let value: String
    let label: LocalizedStringKey

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(color)
                .clipShape(.rect(cornerRadius: 8))
            Text(value)
                .font(.headline.bold())
                .monospacedDigit()
                .foregroundStyle(AttendanceTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AttendanceTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TodayMetricDivider: View {
    var body: some View {
        Rectangle()
            .fill(.gray.opacity(0.14))
            .frame(width: 1, height: 72)
    }
}

private struct CantoneseLyricSharePanel: View {
    let record: AttendanceRecord

    private var provider: CantoneseLyricShareProvider {
        CantoneseLyricShareProvider(timeZone: .current)
    }

    var body: some View {
        AttendancePanel {
            VStack(alignment: .leading, spacing: 14) {
                Label("粤语歌词", systemImage: "music.note.list")
                    .font(.headline)
                    .foregroundStyle(AttendanceTheme.ink)

                LyricShareRow(
                    share: provider.share(for: record.clockInAt, moment: .clockIn),
                    color: AttendanceTheme.accent
                )

                if let clockOutAt = record.actualClockOutAt {
                    Divider()
                    LyricShareRow(
                        share: provider.share(for: clockOutAt, moment: .clockOut),
                        color: AttendanceTheme.mint
                    )
                }
            }
        }
    }
}

private struct LyricShareRow: View {
    @Environment(\.openURL) private var openURL

    let share: CantoneseLyricShare
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                openInAppleMusic()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: share.moment == .clockIn ? "sunrise.fill" : "sunset.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(color)
                            .clipShape(.rect(cornerRadius: 8))

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(color, .white)
                            .background(Circle().fill(.white))
                            .offset(x: 3, y: 3)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Text(verbatim: share.momentLabel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AttendanceTheme.ink)
                            Text(verbatim: share.occasion.label)
                                .font(.caption2)
                                .foregroundStyle(AttendanceTheme.secondaryInk)
                        }

                        Text(verbatim: "「\(share.excerpt.line)」")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AttendanceTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(verbatim: "《\(share.excerpt.songTitle)》 · \(share.excerpt.artist)")
                            .font(.caption)
                            .foregroundStyle(AttendanceTheme.secondaryInk)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(share.excerpt.appleMusicSearchURL == nil)
            .accessibilityLabel(Text("在 Apple Music 中播放"))

            ShareLink(item: share.shareText, subject: Text(verbatim: share.shareTitle)) {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .tint(color)
            .accessibilityLabel(Text("分享"))
        }
    }

    private func openInAppleMusic() {
        guard let url = share.excerpt.appleMusicSearchURL else { return }
        openURL(url) { accepted in
            guard !accepted, let webURL = share.excerpt.appleMusicWebSearchURL else { return }
            openURL(webURL)
        }
    }
}

private struct ManualClockInSheet: View {
    @Environment(\.dismiss) private var dismiss
    let store: AttendanceStore
    let existingRecord: AttendanceRecord?
    @State private var selectedTime: Date
    @State private var validationMessage: String?

    init(store: AttendanceStore, existingRecord: AttendanceRecord?) {
        self.store = store
        self.existingRecord = existingRecord
        _selectedTime = State(initialValue: existingRecord?.clockInAt ?? Date())
    }

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
                            validationMessage = String(localized: "不能选择未来时间。")
                            return
                        }
                        if let existingRecord {
                            store.update(
                                record: existingRecord,
                                clockInAt: selectedTime,
                                actualClockOutAt: existingRecord.actualClockOutAt
                            )
                        } else {
                            store.clockIn(at: selectedTime, isManual: true)
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
