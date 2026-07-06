import Foundation

public struct AttendanceWidgetSnapshot: Codable, Sendable, Equatable {
    public let generatedAt: Date
    public let dayKey: String
    public let isWorkday: Bool
    public let hasClockIn: Bool
    public let clockInAt: Date?
    public let targetEndAt: Date?
    public let status: AttendanceStatus
    public let validAttendanceDays: Int
    public let requiredDays: Int
    public let totalWorkdays: Int
    public let remainingNeeded: Int
    public let monthPassed: Bool
    public let monthLabel: String
    public let nextRefreshAt: Date

    public init(
        generatedAt: Date,
        dayKey: String,
        isWorkday: Bool,
        hasClockIn: Bool,
        clockInAt: Date?,
        targetEndAt: Date?,
        status: AttendanceStatus,
        validAttendanceDays: Int,
        requiredDays: Int,
        totalWorkdays: Int,
        remainingNeeded: Int,
        monthPassed: Bool,
        monthLabel: String,
        nextRefreshAt: Date
    ) {
        self.generatedAt = generatedAt
        self.dayKey = dayKey
        self.isWorkday = isWorkday
        self.hasClockIn = hasClockIn
        self.clockInAt = clockInAt
        self.targetEndAt = targetEndAt
        self.status = status
        self.validAttendanceDays = validAttendanceDays
        self.requiredDays = requiredDays
        self.totalWorkdays = totalWorkdays
        self.remainingNeeded = remainingNeeded
        self.monthPassed = monthPassed
        self.monthLabel = monthLabel
        self.nextRefreshAt = nextRefreshAt
    }
}
