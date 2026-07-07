import AttendanceKit
import Foundation
import SwiftData

@Model
final class AttendanceStorageRecord {
    var id: UUID = UUID()
    var dayKey: String = ""
    var clockInAt: Date = Date()
    var targetEndAt: Date = Date()
    var actualClockOutAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sourceDevice: String = ""
    var isManualClockIn: Bool = false

    init(record: AttendanceRecord) {
        self.id = record.id
        self.dayKey = record.dayKey
        self.clockInAt = record.clockInAt
        self.targetEndAt = record.targetEndAt
        self.actualClockOutAt = record.actualClockOutAt
        self.createdAt = record.createdAt
        self.updatedAt = record.updatedAt
        self.sourceDevice = record.sourceDevice
        self.isManualClockIn = record.isManualClockIn
    }

    func apply(_ record: AttendanceRecord) {
        id = record.id
        dayKey = record.dayKey
        clockInAt = record.clockInAt
        targetEndAt = record.targetEndAt
        actualClockOutAt = record.actualClockOutAt
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        sourceDevice = record.sourceDevice
        isManualClockIn = record.isManualClockIn
    }

    func domainRecord() -> AttendanceRecord {
        AttendanceRecord(
            id: id,
            dayKey: dayKey,
            clockInAt: clockInAt,
            targetEndAt: targetEndAt,
            actualClockOutAt: actualClockOutAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceDevice: sourceDevice,
            isManualClockIn: isManualClockIn
        )
    }
}
