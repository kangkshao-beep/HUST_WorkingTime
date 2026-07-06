import Foundation
import XCTest
@testable import AttendanceKit

final class DuplicateAndMonthProgressTests: XCTestCase {
    func testNewerUpdatedAtWins() {
        let older = makeRecord(2026, 7, 6, updatedAt: makeDate(2026, 7, 6, 10))
        let newer = makeRecord(2026, 7, 6, hour: 8, updatedAt: makeDate(2026, 7, 6, 11))
        let canonical = AttendanceConflictResolver().canonicalRecord(from: [older, newer])
        XCTAssertEqual(canonical?.clockInAt, newer.clockInAt)
    }

    func testTieUsesDeterministicUUIDOrder() {
        let updated = makeDate(2026, 7, 6, 10)
        let lowID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let highID = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!
        let low = makeRecord(2026, 7, 6, updatedAt: updated, id: lowID)
        let high = makeRecord(2026, 7, 6, hour: 8, updatedAt: updated, id: highID)
        let canonical = AttendanceConflictResolver().canonicalRecord(from: [low, high])
        XCTAssertEqual(canonical?.id, highID)
    }

    func testDuplicateDoesNotDoubleCountMonthProgress() {
        let engine = AttendanceEngine()
        let older = makeRecord(2026, 7, 6, updatedAt: makeDate(2026, 7, 6, 10))
        let newer = makeRecord(2026, 7, 6, hour: 8, updatedAt: makeDate(2026, 7, 6, 11))
        let progress = engine.monthProgress(
            monthContaining: makeDate(2026, 7, 15),
            records: [older, newer],
            now: makeDate(2026, 7, 15),
            calendar: makeCalendar()
        )
        XCTAssertEqual(progress.validAttendanceDays, 1)
    }

    func testFutureWeekdaysAndWeekendsAreNotMissed() {
        let engine = AttendanceEngine()
        let progress = engine.monthProgress(
            monthContaining: makeDate(2026, 7, 15),
            records: [makeRecord(2026, 7, 13), makeRecord(2026, 7, 14)],
            now: makeDate(2026, 7, 15, 9),
            calendar: makeCalendar()
        )
        XCTAssertEqual(progress.missedPastWorkdays, 6)
        XCTAssertEqual(progress.elapsedWorkdays, 11)
    }

    func testPassedThresholds() {
        let engine = AttendanceEngine()
        let calendar = makeCalendar()
        let julyWorkdays = calendar.weekdaysInMonth(containing: makeDate(2026, 7, 1))
        let first18 = julyWorkdays.prefix(18).map { day in
            makeRecord(2026, 7, Int(calendar.calendar.component(.day, from: day)))
        }
        let first19 = julyWorkdays.prefix(19).map { day in
            makeRecord(2026, 7, Int(calendar.calendar.component(.day, from: day)))
        }
        XCTAssertFalse(engine.monthProgress(monthContaining: makeDate(2026, 7, 1), records: first18, now: makeDate(2026, 7, 31), calendar: calendar).passed)
        XCTAssertTrue(engine.monthProgress(monthContaining: makeDate(2026, 7, 1), records: first19, now: makeDate(2026, 7, 31), calendar: calendar).passed)
    }
}
