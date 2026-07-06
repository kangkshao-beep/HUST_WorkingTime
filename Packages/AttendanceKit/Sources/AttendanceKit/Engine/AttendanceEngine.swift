import Foundation

public struct AttendanceEngine: Sendable {
    private let conflictResolver: AttendanceConflictResolver

    public init(conflictResolver: AttendanceConflictResolver = AttendanceConflictResolver()) {
        self.conflictResolver = conflictResolver
    }

    public func targetEnd(for clockInAt: Date, policy: AttendancePolicy = .default) -> Date {
        clockInAt.addingTimeInterval(policy.targetDuration)
    }

    public func status(
        record: AttendanceRecord?,
        now: Date,
        policy: AttendancePolicy = .default,
        calendar: WorkdayCalendar
    ) -> AttendanceStatus {
        guard calendar.isWorkday(now, policy: policy) else {
            return .weekend
        }
        guard let record else {
            return .notClockedIn
        }
        if let actualClockOutAt = record.actualClockOutAt {
            return actualClockOutAt >= record.targetEndAt ? .completed : .clockedOutEarly
        }
        return now >= record.targetEndAt ? .targetReached : .working
    }

    public func remainingDuration(record: AttendanceRecord, now: Date) -> TimeInterval {
        max(record.targetEndAt.timeIntervalSince(now), 0)
    }

    public func dailyProgress(
        record: AttendanceRecord,
        now: Date,
        policy: AttendancePolicy = .default
    ) -> Double {
        guard policy.targetDuration > 0 else { return 1 }
        let effectiveEnd = record.actualClockOutAt ?? now
        let elapsed = max(effectiveEnd.timeIntervalSince(record.clockInAt), 0)
        return min(elapsed / policy.targetDuration, 1)
    }

    public func isValidAttendance(
        record: AttendanceRecord,
        policy: AttendancePolicy = .default,
        calendar: WorkdayCalendar
    ) -> Bool {
        calendar.isWorkday(record.clockInAt, policy: policy)
            && record.dayKey == calendar.dayKey(for: record.clockInAt)
            && record.targetEndAt >= record.clockInAt
    }

    public func isDailyTargetMet(
        record: AttendanceRecord,
        now: Date,
        policy: AttendancePolicy = .default
    ) -> Bool {
        let effectiveEnd = record.actualClockOutAt ?? now
        return effectiveEnd >= record.targetEndAt
            && effectiveEnd.timeIntervalSince(record.clockInAt) >= policy.targetDuration
    }

    public func monthProgress(
        monthContaining date: Date,
        records: [AttendanceRecord],
        now: Date,
        policy: AttendancePolicy = .default,
        calendar: WorkdayCalendar
    ) -> MonthProgress {
        let interval = calendar.monthInterval(containing: date)
        let canonical = conflictResolver.canonicalRecords(from: records)
        let monthRecords = canonical.filter { record in
            record.clockInAt >= interval.start && record.clockInAt < interval.end
        }
        let validAttendanceDays = monthRecords.filter {
            isValidAttendance(record: $0, policy: policy, calendar: calendar)
        }.count
        let totalWorkdays = calendar.weekdaysInMonth(containing: date, policy: policy).count
        let requiredDays = Int(ceil(Double(totalWorkdays) * policy.requiredAttendanceRate))
        let remainingNeeded = max(requiredDays - validAttendanceDays, 0)
        let progressToRequirement = requiredDays == 0
            ? 1
            : min(Double(validAttendanceDays) / Double(requiredDays), 1)

        return MonthProgress(
            monthStart: interval.start,
            monthEnd: interval.end,
            totalWorkdays: totalWorkdays,
            validAttendanceDays: validAttendanceDays,
            requiredDays: requiredDays,
            remainingNeeded: remainingNeeded,
            passed: validAttendanceDays >= requiredDays,
            progressToRequirement: progressToRequirement,
            elapsedWorkdays: calendar.elapsedWorkdaysInCurrentMonth(now: now, policy: policy),
            missedPastWorkdays: calendar.missedPastWorkdays(records: monthRecords, now: now, policy: policy)
        )
    }
}
