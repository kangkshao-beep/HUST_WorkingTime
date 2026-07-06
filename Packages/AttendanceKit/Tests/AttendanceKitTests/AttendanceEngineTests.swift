import Foundation
import XCTest
@testable import AttendanceKit

final class AttendanceEngineTests: XCTestCase {
    func testNoRecordStatus() {
        let engine = AttendanceEngine()
        XCTAssertEqual(engine.status(record: nil, now: makeDate(2026, 7, 6, 9), calendar: makeCalendar()), .notClockedIn)
    }

    func testWeekendStatus() {
        let engine = AttendanceEngine()
        XCTAssertEqual(engine.status(record: nil, now: makeDate(2026, 7, 11, 9), calendar: makeCalendar()), .weekend)
    }

    func testClockInAtNineTargetsFivePM() {
        let engine = AttendanceEngine()
        let clockIn = makeDate(2026, 7, 6, 9)
        XCTAssertEqual(engine.targetEnd(for: clockIn), makeDate(2026, 7, 6, 17))
    }

    func testRemainingAtNoonIsFiveHours() {
        let engine = AttendanceEngine()
        let record = makeRecord(2026, 7, 6)
        XCTAssertEqual(engine.remainingDuration(record: record, now: makeDate(2026, 7, 6, 12)), 5 * 60 * 60, accuracy: 0.001)
    }

    func testTargetReachedWithoutClockOut() {
        let engine = AttendanceEngine()
        let record = makeRecord(2026, 7, 6)
        XCTAssertEqual(engine.status(record: record, now: makeDate(2026, 7, 6, 17), calendar: makeCalendar()), .targetReached)
        XCTAssertTrue(engine.isDailyTargetMet(record: record, now: makeDate(2026, 7, 6, 17)))
    }

    func testAfterTargetStillTargetReachedUntilClockOut() {
        let engine = AttendanceEngine()
        let record = makeRecord(2026, 7, 6)
        XCTAssertEqual(engine.status(record: record, now: makeDate(2026, 7, 6, 18), calendar: makeCalendar()), .targetReached)
    }

    func testEarlyClockOutIsSeparateFromValidAttendance() {
        let engine = AttendanceEngine()
        let record = makeRecord(2026, 7, 6)
        record.actualClockOutAt = makeDate(2026, 7, 6, 16)
        XCTAssertEqual(engine.status(record: record, now: makeDate(2026, 7, 6, 16), calendar: makeCalendar()), .clockedOutEarly)
        XCTAssertTrue(engine.isValidAttendance(record: record, calendar: makeCalendar()))
        XCTAssertFalse(engine.isDailyTargetMet(record: record, now: makeDate(2026, 7, 6, 18)))
    }

    func testCompletedWithActualClockOutAfterTarget() {
        let engine = AttendanceEngine()
        let record = makeRecord(2026, 7, 6)
        record.actualClockOutAt = makeDate(2026, 7, 6, 17, 30)
        XCTAssertEqual(engine.status(record: record, now: makeDate(2026, 7, 6, 17, 30), calendar: makeCalendar()), .completed)
        XCTAssertTrue(engine.isDailyTargetMet(record: record, now: makeDate(2026, 7, 6, 17, 30)))
    }

    func testCountdownPersistenceUsesAbsoluteDates() {
        let engine = AttendanceEngine()
        let record = makeRecord(2026, 7, 6)
        XCTAssertEqual(engine.remainingDuration(record: record, now: makeDate(2026, 7, 6, 10)), 7 * 60 * 60, accuracy: 0.001)
        XCTAssertEqual(engine.remainingDuration(record: record, now: makeDate(2026, 7, 6, 14)), 3 * 60 * 60, accuracy: 0.001)
    }
}
