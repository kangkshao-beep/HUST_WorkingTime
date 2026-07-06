import Foundation

public enum AttendanceStatus: String, Codable, Sendable, Equatable, CaseIterable {
    case weekend
    case notClockedIn
    case working
    case targetReached
    case clockedOutEarly
    case completed
}
