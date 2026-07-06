import Foundation

public final class AttendanceRecord: Identifiable, @unchecked Sendable {
    public var id: UUID
    public var dayKey: String
    public var clockInAt: Date
    public var targetEndAt: Date
    public var actualClockOutAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var sourceDevice: String
    public var isManualClockIn: Bool

    public init(
        id: UUID = UUID(),
        dayKey: String,
        clockInAt: Date,
        targetEndAt: Date,
        actualClockOutAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sourceDevice: String = "unknown",
        isManualClockIn: Bool = false
    ) {
        self.id = id
        self.dayKey = dayKey
        self.clockInAt = clockInAt
        self.targetEndAt = targetEndAt
        self.actualClockOutAt = actualClockOutAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceDevice = sourceDevice
        self.isManualClockIn = isManualClockIn
    }
}
