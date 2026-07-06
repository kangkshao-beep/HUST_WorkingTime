import Foundation
import XCTest
@testable import AttendanceKit

func makeCalendar(_ identifier: String = "Asia/Shanghai") -> WorkdayCalendar {
    WorkdayCalendar(timeZone: TimeZone(identifier: identifier)!)
}

func makeDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int = 0,
    _ minute: Int = 0,
    _ second: Int = 0,
    timeZoneID: String = "Asia/Shanghai"
) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: timeZoneID)!
    calendar.locale = Locale(identifier: "en_US_POSIX")
    var components = DateComponents()
    components.timeZone = calendar.timeZone
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    return calendar.date(from: components)!
}

func makeRecord(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    hour: Int = 9,
    minute: Int = 0,
    updatedAt: Date? = nil,
    id: UUID = UUID(),
    timeZoneID: String = "Asia/Shanghai"
) -> AttendanceRecord {
    let calendar = makeCalendar(timeZoneID)
    let clockIn = makeDate(year, month, day, hour, minute, timeZoneID: timeZoneID)
    let engine = AttendanceEngine()
    return AttendanceRecord(
        id: id,
        dayKey: calendar.dayKey(for: clockIn),
        clockInAt: clockIn,
        targetEndAt: engine.targetEnd(for: clockIn),
        createdAt: updatedAt ?? clockIn,
        updatedAt: updatedAt ?? clockIn,
        sourceDevice: "test"
    )
}
