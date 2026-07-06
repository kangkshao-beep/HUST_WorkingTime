import Foundation

public struct MonthProgress: Sendable, Equatable {
    public let monthStart: Date
    public let monthEnd: Date
    public let totalWorkdays: Int
    public let validAttendanceDays: Int
    public let requiredDays: Int
    public let remainingNeeded: Int
    public let passed: Bool
    public let progressToRequirement: Double
    public let elapsedWorkdays: Int
    public let missedPastWorkdays: Int

    public init(
        monthStart: Date,
        monthEnd: Date,
        totalWorkdays: Int,
        validAttendanceDays: Int,
        requiredDays: Int,
        remainingNeeded: Int,
        passed: Bool,
        progressToRequirement: Double,
        elapsedWorkdays: Int,
        missedPastWorkdays: Int
    ) {
        self.monthStart = monthStart
        self.monthEnd = monthEnd
        self.totalWorkdays = totalWorkdays
        self.validAttendanceDays = validAttendanceDays
        self.requiredDays = requiredDays
        self.remainingNeeded = remainingNeeded
        self.passed = passed
        self.progressToRequirement = progressToRequirement
        self.elapsedWorkdays = elapsedWorkdays
        self.missedPastWorkdays = missedPastWorkdays
    }
}
