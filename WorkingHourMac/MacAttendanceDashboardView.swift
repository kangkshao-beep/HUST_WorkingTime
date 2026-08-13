import AttendanceKit
import SwiftData
import SwiftUI

private func macLocalized(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

struct MacAttendanceDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = AttendanceStore.shared
    @State private var selection: MacAttendanceSection? = .today
    @State private var showsStorageWarning = false

    private let storageWarning = SharedModelContainer.shared.lastInitializationErrorDescription

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("工作台") {
                    MacSidebarItem(title: macLocalized("今天"), systemImage: "clock", value: .today)
                    MacSidebarItem(title: macLocalized("本月"), systemImage: "calendar", value: .month)
                }

                Section("数据") {
                    MacSidebarItem(title: macLocalized("打卡记录"), systemImage: "list.bullet.rectangle", value: .history)
                }
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 220)
        } detail: {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                switch selection ?? .today {
                case .today:
                    MacTodayView(store: store, now: context.date)
                case .month:
                    MacMonthView(store: store, now: context.date)
                case .history:
                    MacHistoryView(store: store)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if let storageWarning {
                        Button {
                            showsStorageWarning.toggle()
                        } label: {
                            Image(systemName: "externaldrive.badge.exclamationmark")
                        }
                        .help("存储状态")
                        .popover(isPresented: $showsStorageWarning, arrowEdge: .bottom) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("当前使用本机存储", systemImage: "externaldrive")
                                    .font(.headline)
                                Text(storageWarning)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .frame(width: 320)
                        }
                    }

                    Button {
                        store.load()
                        store.refreshSnapshotAndWidgets()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("刷新")
                }
            }
        }
        .navigationTitle((selection ?? .today).title)
        .task {
            store.configure(modelContext: modelContext)
        }
        .onAppear {
            store.configure(modelContext: modelContext)
        }
    }
}

private enum MacAttendanceSection: String, CaseIterable, Hashable {
    case today
    case month
    case history

    var title: String {
        switch self {
        case .today: macLocalized("今天")
        case .month: macLocalized("本月")
        case .history: macLocalized("打卡记录")
        }
    }
}

private struct MacSidebarItem: View {
    let title: String
    let systemImage: String
    let value: MacAttendanceSection

    var body: some View {
        Label(title, systemImage: systemImage)
            .tag(value)
    }
}

private struct MacTodayView: View {
    @Environment(\.locale) private var locale

    let store: AttendanceStore
    let now: Date

    var body: some View {
        let record = store.todayRecord(now: now)
        let status = store.status(for: record, now: now)
        let monthProgress = store.monthProgress(containing: now, now: now)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MacPageHeader(
                    eyebrow: now.formatted(
                        .dateTime.year().month().day().weekday(.wide).locale(locale)
                    ),
                    title: greeting(for: status),
                    status: status
                )
                .padding(.bottom, 26)

                HStack(alignment: .top, spacing: 30) {
                    VStack(alignment: .leading, spacing: 26) {
                        MacTodayFocus(store: store, record: record, status: status, now: now)

                        if let message = store.lastErrorMessage {
                            Label(message, systemImage: "exclamationmark.triangle")
                                .font(.callout)
                                .foregroundStyle(.orange)
                                .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    MacMonthSummary(progress: monthProgress)
                        .frame(width: 220, alignment: .leading)
                }
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 30)
            .frame(maxWidth: 980, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func greeting(for status: AttendanceStatus) -> String {
        switch status {
        case .weekend: macLocalized("今天休息")
        case .notClockedIn: macLocalized("准备开始工作")
        case .working: macLocalized("工作进行中")
        case .targetReached: macLocalized("今日目标已完成")
        case .clockedOutEarly: macLocalized("今天已结束")
        case .completed: macLocalized("今天已完成")
        }
    }
}

private struct MacTodayFocus: View {
    let store: AttendanceStore
    let record: AttendanceRecord?
    let status: AttendanceStatus
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let record {
                VStack(alignment: .leading, spacing: 6) {
                    Text(primaryLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    primaryValue(for: record)
                        .font(.system(size: 54, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                }

                ProgressView(value: store.dailyProgress(for: record, now: now))
                    .progressViewStyle(.linear)
                    .tint(progressTint)

                MacTimeStrip(record: record)
                MacCantoneseLyricShareSection(record: record)

                if record.actualClockOutAt == nil {
                    Button {
                        store.clockOut(record: record)
                    } label: {
                        Label("结束今天工作", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: status == .weekend ? "cup.and.saucer" : "play.circle")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.secondary)

                    Text(status == .weekend ? macLocalized("没有安排") : macLocalized("尚未打卡"))
                        .font(.system(size: 34, weight: .semibold))

                    if status == .notClockedIn {
                        Button {
                            store.clockInNow()
                        } label: {
                            Label("现在打卡", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding(.vertical, 20)
            }
        }
    }

    private var primaryLabel: String {
        switch status {
        case .working: macLocalized("距离今日目标")
        case .targetReached: macLocalized("目标已达成")
        case .clockedOutEarly, .completed: macLocalized("今日工作时长")
        case .weekend, .notClockedIn: ""
        }
    }

    @ViewBuilder
    private func primaryValue(for record: AttendanceRecord) -> some View {
        switch status {
        case .working:
            Text(record.targetEndAt, style: .timer)
        case .targetReached:
            Text("00:00:00")
                .foregroundStyle(.green)
        case .clockedOutEarly, .completed:
            Text(formattedDuration(from: record.clockInAt, to: record.actualClockOutAt ?? now))
        case .weekend, .notClockedIn:
            EmptyView()
        }
    }

    private var progressTint: Color {
        switch status {
        case .targetReached, .completed: .green
        case .clockedOutEarly: .orange
        default: .accentColor
        }
    }

    private func formattedDuration(from start: Date, to end: Date) -> String {
        let interval = max(end.timeIntervalSince(start), 0)
        let hours = Int(interval) / 3_600
        let minutes = (Int(interval) % 3_600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

private struct MacTimeStrip: View {
    @Environment(\.locale) private var locale

    let record: AttendanceRecord

    var body: some View {
        HStack(spacing: 0) {
            MacTimeMetric(title: macLocalized("上班"), value: time(record.clockInAt), systemImage: "arrow.right.circle")
            Divider().frame(height: 42)
            MacTimeMetric(title: macLocalized("目标"), value: targetTime, systemImage: "flag.checkered")
            Divider().frame(height: 42)
            MacTimeMetric(
                title: macLocalized("下班"),
                value: record.actualClockOutAt.map(time) ?? "--:--",
                systemImage: "stop.circle"
            )
        }
        .padding(.vertical, 14)
        .background(.quaternary.opacity(0.45))
        .clipShape(.rect(cornerRadius: 6))
    }

    private func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute().locale(locale))
    }

    private var targetTime: String {
        let prefix = Calendar.current.isDate(record.clockInAt, inSameDayAs: record.targetEndAt)
            ? ""
            : macLocalized("次日 ")
        return prefix + time(record.targetEndAt)
    }
}

private struct MacTimeMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}

private struct MacCantoneseLyricShareSection: View {
    @State private var clockInVariation = 0
    @State private var clockOutVariation = 0

    let record: AttendanceRecord

    private var provider: CantoneseLyricShareProvider {
        CantoneseLyricShareProvider(timeZone: .current)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label(macLocalized("粤语歌词"), systemImage: "music.note.list")
                .font(.headline)

            MacLyricShareRow(
                share: provider.share(
                    for: record.clockInAt,
                    moment: .clockIn,
                    variation: clockInVariation
                ),
                color: .accentColor,
                onShuffle: { clockInVariation += 1 }
            )

            if let clockOutAt = record.actualClockOutAt {
                Divider()
                MacLyricShareRow(
                    share: provider.share(
                        for: clockOutAt,
                        moment: .clockOut,
                        variation: clockOutVariation
                    ),
                    color: .green,
                    onShuffle: { clockOutVariation += 1 }
                )
            }
        }
        .padding(.top, 4)
    }
}

private struct MacLyricShareRow: View {
    @Environment(\.openURL) private var openURL

    let share: CantoneseLyricShare
    let color: Color
    let onShuffle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: share.moment == .clockIn ? "sunrise.fill" : "sunset.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(color)
                    .clipShape(.rect(cornerRadius: 8))

                Text(verbatim: share.momentLabel)
                    .font(.headline.weight(.semibold))

                Text(verbatim: share.occasion.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if canShuffle {
                    Button(action: onShuffle) {
                        Image(systemName: "shuffle")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.borderless)
                    .help(macLocalized("换一首粤语歌"))
                    .accessibilityLabel(macLocalized("换一首粤语歌"))
                }

                ShareLink(item: share.shareText, subject: Text(verbatim: share.shareTitle)) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .help(macLocalized("分享"))
                .accessibilityLabel(macLocalized("分享"))
            }

            Button {
                openInAppleMusic()
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "「\(share.excerpt.line)」")
                        .font(.system(size: 42, weight: .semibold))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(color)
                        Text(verbatim: "《\(share.excerpt.songTitle)》 · \(share.excerpt.artist)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(share.excerpt.appleMusicSearchURL == nil)
            .help(macLocalized("在 Apple Music 中播放"))
            .accessibilityLabel(macLocalized("在 Apple Music 中播放"))
        }
    }

    private var canShuffle: Bool {
        if case .solarTerm = share.occasion {
            return true
        }
        return false
    }

    private func openInAppleMusic() {
        guard let url = share.excerpt.appleMusicSearchURL else { return }
        openURL(url) { accepted in
            guard !accepted, let webURL = share.excerpt.appleMusicWebSearchURL else { return }
            openURL(webURL)
        }
    }
}

private struct MacMonthView: View {
    @Environment(\.locale) private var locale

    let store: AttendanceStore
    let now: Date

    var body: some View {
        let progress = store.monthProgress(containing: now, now: now)

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                MacPageHeader(
                    eyebrow: now.formatted(.dateTime.year().month(.wide).locale(locale)),
                    title: macLocalized("本月出勤"),
                    statusText: progress.passed ? macLocalized("已达标") : macLocalized("进行中"),
                    statusColor: progress.passed ? .green : .secondary
                )

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(progress.validAttendanceDays)")
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("/ \(progress.requiredDays) 天")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: progress.progressToRequirement)
                    .tint(progress.passed ? .green : .accentColor)

                HStack(spacing: 0) {
                    MacMonthMetric(title: macLocalized("当月工作日"), value: "\(progress.totalWorkdays)")
                    Divider().frame(height: 44)
                    MacMonthMetric(title: macLocalized("已经过"), value: "\(progress.elapsedWorkdays)")
                    Divider().frame(height: 44)
                    MacMonthMetric(title: macLocalized("缺勤"), value: "\(progress.missedPastWorkdays)")
                    Divider().frame(height: 44)
                    MacMonthMetric(title: macLocalized("还需打卡"), value: "\(progress.remainingNeeded)")
                }
                .padding(.vertical, 16)
                .background(.quaternary.opacity(0.45))
                .clipShape(.rect(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 12) {
                    Text("最近打卡")
                        .font(.headline)
                    MacRecordList(records: Array(store.records.prefix(6)), store: store)
                }
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 30)
            .frame(maxWidth: 920, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct MacMonthSummary: View {
    let progress: MonthProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("本月")
                    .font(.headline)
                Spacer()
                Text(progress.passed ? macLocalized("已达标") : macLocalized("进行中"))
                    .font(.caption)
                    .foregroundStyle(progress.passed ? .green : .secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(progress.validAttendanceDays)")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("/ \(progress.requiredDays) 天")
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress.progressToRequirement)
                .tint(progress.passed ? .green : .accentColor)

            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
                GridRow {
                    Text("还需打卡")
                    Text("\(progress.remainingNeeded) 天")
                        .foregroundStyle(.primary)
                }
                GridRow {
                    Text("本月工作日")
                    Text("\(progress.totalWorkdays) 天")
                        .foregroundStyle(.primary)
                }
                GridRow {
                    Text("已缺勤")
                    Text("\(progress.missedPastWorkdays) 天")
                        .foregroundStyle(.primary)
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }
}

private struct MacMonthMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
    }
}

private struct MacHistoryView: View {
    let store: AttendanceStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MacPageHeader(
                    eyebrow: String(localized: "共 \(store.records.count) 条记录"),
                    title: macLocalized("打卡记录"),
                    statusText: macLocalized("自动同步"),
                    statusColor: .secondary
                )

                if store.records.isEmpty {
                    ContentUnavailableView("暂无记录", systemImage: "calendar.badge.clock")
                        .frame(maxWidth: .infinity, minHeight: 340)
                } else {
                    MacRecordList(records: store.records, store: store)
                }
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 30)
            .frame(maxWidth: 920, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct MacRecordList: View {
    @Environment(\.locale) private var locale

    let records: [AttendanceRecord]
    let store: AttendanceStore

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            record.clockInAt.formatted(
                                .dateTime.month().day().weekday(.abbreviated).locale(locale)
                            )
                        )
                            .font(.body.weight(.medium))
                        Text(record.sourceDevice)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(width: 130, alignment: .leading)

                    Text(record.clockInAt.formatted(date: .omitted, time: .shortened))
                        .monospacedDigit()

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text((record.actualClockOutAt ?? record.targetEndAt).formatted(date: .omitted, time: .shortened))
                        .monospacedDigit()

                    Spacer()

                    Label(
                        record.actualClockOutAt == nil ? macLocalized("进行中") : macLocalized("已结束"),
                        systemImage: record.actualClockOutAt == nil ? "circle.fill" : "checkmark.circle"
                    )
                        .font(.caption)
                        .foregroundStyle(record.actualClockOutAt == nil ? Color.accentColor : .secondary)
                }
                .padding(.vertical, 12)
                .contextMenu {
                    Button("删除记录", role: .destructive) {
                        store.delete(record: record)
                    }
                }

                if index < records.count - 1 {
                    Divider()
                }
            }
        }
    }
}

private struct MacPageHeader: View {
    let eyebrow: String
    let title: String
    let statusText: String
    let statusColor: Color

    init(eyebrow: String, title: String, status: AttendanceStatus) {
        self.eyebrow = eyebrow
        self.title = title
        switch status {
        case .weekend:
            statusText = macLocalized("休息日")
            statusColor = .secondary
        case .notClockedIn:
            statusText = macLocalized("未打卡")
            statusColor = .secondary
        case .working:
            statusText = macLocalized("计时中")
            statusColor = .accentColor
        case .targetReached, .completed:
            statusText = macLocalized("已完成")
            statusColor = .green
        case .clockedOutEarly:
            statusText = macLocalized("提前结束")
            statusColor = .orange
        }
    }

    init(eyebrow: String, title: String, statusText: String, statusColor: Color) {
        self.eyebrow = eyebrow
        self.title = title
        self.statusText = statusText
        self.statusColor = statusColor
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
            }

            Spacer()

            HStack(spacing: 7) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(statusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
