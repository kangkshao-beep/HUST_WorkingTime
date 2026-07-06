import Foundation
import XCTest
@testable import AttendanceKit

final class RequiredAttendanceTests: XCTestCase {
    func testRequiredAttendanceRounding() {
        XCTAssertEqual(Int(ceil(Double(20) * 0.80)), 16)
        XCTAssertEqual(Int(ceil(Double(21) * 0.80)), 17)
        XCTAssertEqual(Int(ceil(Double(22) * 0.80)), 18)
        XCTAssertEqual(Int(ceil(Double(23) * 0.80)), 19)
    }

    func testEngineUsesRequiredAttendanceRounding() {
        let engine = AttendanceEngine()
        let calendar = makeCalendar()
        XCTAssertEqual(engine.monthProgress(monthContaining: makeDate(2026, 2, 1), records: [], now: makeDate(2026, 2, 1), calendar: calendar).requiredDays, 16)
        XCTAssertEqual(engine.monthProgress(monthContaining: makeDate(2026, 8, 1), records: [], now: makeDate(2026, 8, 1), calendar: calendar).requiredDays, 17)
        XCTAssertEqual(engine.monthProgress(monthContaining: makeDate(2025, 9, 1), records: [], now: makeDate(2025, 9, 1), calendar: calendar).requiredDays, 18)
        XCTAssertEqual(engine.monthProgress(monthContaining: makeDate(2026, 7, 1), records: [], now: makeDate(2026, 7, 1), calendar: calendar).requiredDays, 19)
    }
}
