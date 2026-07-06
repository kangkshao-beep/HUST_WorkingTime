import Foundation

public struct WorkdayCalendar: Sendable, Equatable {
    public var calendar: Calendar
    public var timeZone: TimeZone

    public init(calendar: Calendar = Calendar(identifier: .gregorian), timeZone: TimeZone = .current) {
        var configured = calendar
        configured.timeZone = timeZone
        configured.locale = Locale(identifier: "en_US_POSIX")
        self.calendar = configured
        self.timeZone = timeZone
    }

    public func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    public func endOfDay(for date: Date) -> Date {
        let start = startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-0.001) ?? start
    }

    public func dayKey(for date: Date) -> String {
        let components = calendar.dateComponents(in: timeZone, from: date)
        return String(
            format: "%04d-%02d-%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    public func isWorkday(_ date: Date, policy: AttendancePolicy = .default) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return policy.workWeekdays.contains(weekday)
    }

    public func monthInterval(containing date: Date) -> DateInterval {
        let components = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: components).map(startOfDay) ?? startOfDay(for: date)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    public func weekdaysInMonth(containing date: Date, policy: AttendancePolicy = .default) -> [Date] {
        let interval = monthInterval(containing: date)
        var cursor = interval.start
        var days: [Date] = []

        while cursor < interval.end {
            if isWorkday(cursor, policy: policy) {
                days.append(cursor)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return days
    }

    public func elapsedWorkdaysInCurrentMonth(now: Date, policy: AttendancePolicy = .default) -> Int {
        let today = startOfDay(for: now)
        return weekdaysInMonth(containing: now, policy: policy).filter { $0 <= today }.count
    }

    public func missedPastWorkdays(
        records: [AttendanceRecord],
        now: Date,
        policy: AttendancePolicy = .default
    ) -> Int {
        let today = startOfDay(for: now)
        let presentKeys = Set(records.map(\.dayKey))
        return weekdaysInMonth(containing: now, policy: policy)
            .filter { $0 < today }
            .filter { !presentKeys.contains(dayKey(for: $0)) }
            .count
    }

    public func nextStartOfDay(after date: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: startOfDay(for: date)) ?? date.addingTimeInterval(24 * 60 * 60)
    }

    public func nextMonthBoundary(after date: Date) -> Date {
        monthInterval(containing: date).end
    }

    public func nextWorkday(after date: Date, policy: AttendancePolicy = .default) -> Date {
        var cursor = nextStartOfDay(after: date)
        for _ in 0..<370 {
            if isWorkday(cursor, policy: policy) {
                return cursor
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return cursor
    }

    public func nextMeaningfulRefreshDate(
        now: Date,
        targetEndAt: Date? = nil,
        policy: AttendancePolicy = .default
    ) -> Date {
        var candidates = [nextStartOfDay(after: now), nextMonthBoundary(after: now)]

        if let targetEndAt, targetEndAt > now {
            candidates.append(targetEndAt)
        }

        if !isWorkday(now, policy: policy) {
            candidates.append(nextWorkday(after: now, policy: policy))
        }

        return candidates.filter { $0 > now }.min() ?? now.addingTimeInterval(15 * 60)
    }
}
