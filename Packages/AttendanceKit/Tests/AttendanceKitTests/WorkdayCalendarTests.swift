import Foundation
import XCTest
@testable import AttendanceKit

final class WorkdayCalendarTests: XCTestCase {
    func testMondayThroughFridayAreWorkdays() {
        let calendar = makeCalendar()
        XCTAssertTrue(calendar.isWorkday(makeDate(2026, 7, 6)))
        XCTAssertTrue(calendar.isWorkday(makeDate(2026, 7, 7)))
        XCTAssertTrue(calendar.isWorkday(makeDate(2026, 7, 8)))
        XCTAssertTrue(calendar.isWorkday(makeDate(2026, 7, 9)))
        XCTAssertTrue(calendar.isWorkday(makeDate(2026, 7, 10)))
    }

    func testSaturdayAndSundayAreNotWorkdays() {
        let calendar = makeCalendar()
        XCTAssertFalse(calendar.isWorkday(makeDate(2026, 7, 11)))
        XCTAssertFalse(calendar.isWorkday(makeDate(2026, 7, 12)))
    }

    func testMonthBeginsAndEndsOnWeekend() {
        let calendar = makeCalendar()
        XCTAssertEqual(calendar.dayKey(for: calendar.monthInterval(containing: makeDate(2026, 8, 15)).start), "2026-08-01")
        XCTAssertEqual(calendar.weekdaysInMonth(containing: makeDate(2026, 8, 15)).count, 21)
        XCTAssertEqual(calendar.weekdaysInMonth(containing: makeDate(2026, 2, 15)).count, 20)
    }

    func testFebruaryNormalAndLeapYear() {
        let calendar = makeCalendar()
        XCTAssertEqual(calendar.weekdaysInMonth(containing: makeDate(2026, 2, 1)).count, 20)
        XCTAssertEqual(calendar.weekdaysInMonth(containing: makeDate(2024, 2, 1)).count, 21)
    }

    func testMonthsWith20To23Weekdays() {
        let calendar = makeCalendar()
        XCTAssertEqual(calendar.weekdaysInMonth(containing: makeDate(2026, 2, 1)).count, 20)
        XCTAssertEqual(calendar.weekdaysInMonth(containing: makeDate(2026, 8, 1)).count, 21)
        XCTAssertEqual(calendar.weekdaysInMonth(containing: makeDate(2026, 7, 1)).count, 23)
        XCTAssertEqual(calendar.weekdaysInMonth(containing: makeDate(2025, 9, 1)).count, 22)
    }

    func testDayKeyStableAcrossTimeZones() {
        let shanghai = makeCalendar("Asia/Shanghai")
        let losAngeles = makeCalendar("America/Los_Angeles")
        let shanghaiDate = makeDate(2026, 7, 6, 0, 30, timeZoneID: "Asia/Shanghai")
        XCTAssertEqual(shanghai.dayKey(for: shanghaiDate), "2026-07-06")
        XCTAssertEqual(losAngeles.dayKey(for: shanghaiDate), "2026-07-05")
    }

    func testMonthBoundary() {
        let calendar = makeCalendar()
        let boundary = calendar.nextMonthBoundary(after: makeDate(2026, 7, 31, 23, 0))
        XCTAssertEqual(calendar.dayKey(for: boundary), "2026-08-01")
    }

    func testNextWorkdayFromWeekend() {
        let calendar = makeCalendar()
        let next = calendar.nextWorkday(after: makeDate(2026, 7, 11, 12, 0))
        XCTAssertEqual(calendar.dayKey(for: next), "2026-07-13")
    }
}
