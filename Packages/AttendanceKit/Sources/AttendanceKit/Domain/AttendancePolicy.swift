import Foundation

public struct AttendancePolicy: Codable, Sendable, Equatable {
    public let targetDuration: TimeInterval
    public let requiredAttendanceRate: Double
    public let workWeekdays: Set<Int>

    public init(
        targetDuration: TimeInterval = 8 * 60 * 60,
        requiredAttendanceRate: Double = 0.80,
        workWeekdays: Set<Int> = Set(2...6)
    ) {
        self.targetDuration = targetDuration
        self.requiredAttendanceRate = requiredAttendanceRate
        self.workWeekdays = workWeekdays
    }

    public static let `default` = AttendancePolicy()
}
