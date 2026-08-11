import AttendanceKit
import SwiftData
import SwiftUI

struct AttendanceMonthView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = AttendanceStore.shared
    @State private var selectedMonth = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                AttendanceScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        MonthSummaryView(progress: store.monthProgress(containing: selectedMonth))
                        MonthCalendarGrid(store: store, selectedMonth: selectedMonth, columns: columns)
                    }
                    .padding()
                }
            }
            .navigationTitle("月度出勤")
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task { store.configure(modelContext: modelContext) }
            .onAppear { store.configure(modelContext: modelContext) }
        }
    }
}

private struct MonthSummaryView: View {
    let progress: MonthProgress

    var body: some View {
        AttendancePanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("本月达标进度")
                        .font(.headline)
                    Spacer()
                    Text(progress.passed ? "已达标" : "未达标")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(progress.passed ? AttendanceTheme.mint : .orange)
                }
                Text("\(progress.validAttendanceDays) / \(progress.requiredDays)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(AttendanceTheme.accent)
                    .monospacedDigit()
                ProgressView(value: progress.progressToRequirement)
                    .tint(AttendanceTheme.accent)
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                    GridRow { Text("当月工作日"); Text("\(progress.totalWorkdays) 天") }
                    GridRow { Text("已有效打卡"); Text("\(progress.validAttendanceDays) 天") }
                    GridRow { Text("80% 所需"); Text("\(progress.requiredDays) 天") }
                    GridRow { Text("距离达标"); Text("还需 \(progress.remainingNeeded) 天") }
                    GridRow { Text("已过去工作日"); Text("\(progress.elapsedWorkdays) 天") }
                    GridRow { Text("已漏打卡"); Text("\(progress.missedPastWorkdays) 天") }
                }
                .font(.subheadline)
                .foregroundStyle(AttendanceTheme.secondaryInk)
            }
        }
    }
}

private struct MonthCalendarGrid: View {
    let store: AttendanceStore
    let selectedMonth: Date
    let columns: [GridItem]

    var body: some View {
        let days = monthDays()
        let recordKeys = Set(store.records.map(\.dayKey))
        AttendancePanel {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { label in
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AttendanceTheme.secondaryInk)
                        .frame(maxWidth: .infinity)
                }
                ForEach(prefixBlanks(), id: \.self) { index in
                    Color.clear.frame(height: 38).id("blank-\(index)")
                }
                ForEach(days, id: \.self) { day in
                    let key = store.workdayCalendar.dayKey(for: day)
                    let isToday = key == store.workdayCalendar.dayKey(for: Date())
                    let isWorkday = store.workdayCalendar.isWorkday(day, policy: store.policy)
                    let hasRecord = recordKeys.contains(key)
                    let isPast = day < store.workdayCalendar.startOfDay(for: Date())
                    Text("\(store.workdayCalendar.calendar.component(.day, from: day))")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(backgroundColor(isWorkday: isWorkday, hasRecord: hasRecord, isPast: isPast))
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isToday ? AttendanceTheme.accent : .clear, lineWidth: 2)
                        }
                        .foregroundStyle(isWorkday ? AttendanceTheme.ink : AttendanceTheme.secondaryInk)
                }
            }
        }
    }

    private func backgroundColor(isWorkday: Bool, hasRecord: Bool, isPast: Bool) -> Color {
        if !isWorkday { return .gray.opacity(0.18) }
        if hasRecord { return AttendanceTheme.mint.opacity(0.28) }
        if isPast { return .red.opacity(0.22) }
        return .clear
    }

    private func monthDays() -> [Date] {
        let interval = store.workdayCalendar.monthInterval(containing: selectedMonth)
        var cursor = interval.start
        var result: [Date] = []
        while cursor < interval.end {
            result.append(cursor)
            guard let next = store.workdayCalendar.calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    private func prefixBlanks() -> [Int] {
        guard let first = monthDays().first else { return [] }
        let weekday = store.workdayCalendar.calendar.component(.weekday, from: first)
        return Array(0..<(weekday - 1))
    }
}
