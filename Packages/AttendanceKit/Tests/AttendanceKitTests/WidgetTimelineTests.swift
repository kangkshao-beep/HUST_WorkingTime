import Foundation
import XCTest
@testable import AttendanceKit

final class WidgetTimelineTests: XCTestCase {
    func testActiveCountdownRefreshesAtTargetEnd() {
        let calendar = makeCalendar()
        let now = makeDate(2026, 7, 6, 12)
        let target = makeDate(2026, 7, 6, 17)
        let snapshot = AttendanceWidgetSnapshot(
            generatedAt: now,
            dayKey: calendar.dayKey(for: now),
            isWorkday: true,
            hasClockIn: true,
            clockInAt: makeDate(2026, 7, 6, 9),
            targetEndAt: target,
            status: .working,
            validAttendanceDays: 1,
            requiredDays: 19,
            totalWorkdays: 23,
            remainingNeeded: 18,
            monthPassed: false,
            monthLabel: "2026-07",
            nextRefreshAt: calendar.nextMeaningfulRefreshDate(now: now, targetEndAt: target)
        )
        XCTAssertEqual(WidgetTimelineLogic().nextRefreshDate(snapshot: snapshot, now: now, calendar: calendar), target)
    }

    func testCompletedRefreshesAtDayBoundary() {
        let calendar = makeCalendar()
        let now = makeDate(2026, 7, 6, 18)
        let snapshot = AttendanceWidgetSnapshot(
            generatedAt: now,
            dayKey: calendar.dayKey(for: now),
            isWorkday: true,
            hasClockIn: true,
            clockInAt: makeDate(2026, 7, 6, 9),
            targetEndAt: makeDate(2026, 7, 6, 17),
            status: .targetReached,
            validAttendanceDays: 1,
            requiredDays: 19,
            totalWorkdays: 23,
            remainingNeeded: 18,
            monthPassed: false,
            monthLabel: "2026-07",
            nextRefreshAt: calendar.nextMeaningfulRefreshDate(now: now)
        )
        XCTAssertEqual(WidgetTimelineLogic().nextRefreshDate(snapshot: snapshot, now: now, calendar: calendar), calendar.nextStartOfDay(after: now))
    }

    func testWeekendRefreshesAtNextWorkday() {
        let calendar = makeCalendar()
        let now = makeDate(2026, 7, 11, 10)
        let snapshot = AttendanceWidgetSnapshot(
            generatedAt: now,
            dayKey: calendar.dayKey(for: now),
            isWorkday: false,
            hasClockIn: false,
            clockInAt: nil,
            targetEndAt: nil,
            status: .weekend,
            validAttendanceDays: 0,
            requiredDays: 19,
            totalWorkdays: 23,
            remainingNeeded: 19,
            monthPassed: false,
            monthLabel: "2026-07",
            nextRefreshAt: calendar.nextWorkday(after: now)
        )
        XCTAssertEqual(WidgetTimelineLogic().nextRefreshDate(snapshot: snapshot, now: now, calendar: calendar), calendar.nextWorkday(after: now))
    }

    func testMonthEndRefresh() {
        let calendar = makeCalendar()
        let now = makeDate(2026, 7, 31, 20)
        let snapshot = AttendanceWidgetSnapshot(
            generatedAt: now,
            dayKey: calendar.dayKey(for: now),
            isWorkday: true,
            hasClockIn: false,
            clockInAt: nil,
            targetEndAt: nil,
            status: .notClockedIn,
            validAttendanceDays: 0,
            requiredDays: 19,
            totalWorkdays: 23,
            remainingNeeded: 19,
            monthPassed: false,
            monthLabel: "2026-07",
            nextRefreshAt: calendar.nextMonthBoundary(after: now)
        )
        XCTAssertEqual(WidgetTimelineLogic().nextRefreshDate(snapshot: snapshot, now: now, calendar: calendar), calendar.nextMonthBoundary(after: now))
    }
}
