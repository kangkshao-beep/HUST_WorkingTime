import XCTest
@testable import AttendanceKit

final class CantoneseLyricShareProviderTests: XCTestCase {
    private let hongKongTimeZone = TimeZone(identifier: "Asia/Hong_Kong")!

    func testTimePeriodsFollowHongKongClock() {
        let provider = CantoneseLyricShareProvider(timeZone: hongKongTimeZone)

        XCTAssertEqual(provider.timePeriod(for: date(2026, 8, 11, 8, 30)), .morning)
        XCTAssertEqual(provider.timePeriod(for: date(2026, 8, 11, 12, 0)), .daytime)
        XCTAssertEqual(provider.timePeriod(for: date(2026, 8, 11, 18, 15)), .evening)
        XCTAssertEqual(provider.timePeriod(for: date(2026, 8, 11, 23, 0)), .night)
        XCTAssertEqual(provider.timePeriod(for: date(2026, 8, 12, 2, 0)), .lateNight)
    }

    func testSolarTermsCoverTheWholeYear() {
        let provider = CantoneseLyricShareProvider(timeZone: hongKongTimeZone)

        XCTAssertEqual(provider.solarTerm(containing: date(2026, 1, 2)), .winterSolstice)
        XCTAssertEqual(provider.solarTerm(containing: date(2026, 2, 4)), .startOfSpring)
        XCTAssertEqual(provider.solarTerm(containing: date(2026, 8, 11)), .startOfAutumn)
        XCTAssertEqual(provider.solarTerm(containing: date(2026, 12, 22)), .winterSolstice)
    }

    func testTraditionalFestivalOverridesSolarTerm() {
        let provider = CantoneseLyricShareProvider(timeZone: hongKongTimeZone)
        let lunarNewYear = date(2026, 2, 17, 8, 30)

        XCTAssertEqual(provider.traditionalFestival(on: lunarNewYear), .lunarNewYear)
        XCTAssertEqual(
            provider.share(for: lunarNewYear, moment: .clockIn).occasion,
            .traditionalFestival(.lunarNewYear)
        )
    }

    func testClockInAndClockOutHaveDifferentContextualLyrics() {
        let provider = CantoneseLyricShareProvider(timeZone: hongKongTimeZone)
        let clockIn = provider.share(for: date(2026, 8, 11, 8, 30), moment: .clockIn)
        let clockOut = provider.share(for: date(2026, 8, 11, 18, 15), moment: .clockOut)

        XCTAssertEqual(clockIn.occasion, .solarTerm(.startOfAutumn))
        XCTAssertEqual(clockIn.momentLabel, "朝早返工")
        XCTAssertEqual(clockOut.momentLabel, "傍晚收工")
        XCTAssertNotEqual(clockIn.excerpt, clockOut.excerpt)
        XCTAssertTrue(clockOut.shareText.contains("《春夏秋冬》 · 張國榮"))
    }

    func testCommercialExcerptsStayShort() {
        XCTAssertFalse(CantoneseLyricShareProvider.allExcerpts.isEmpty)

        for excerpt in CantoneseLyricShareProvider.allExcerpts {
            XCTAssertLessThan(excerpt.line.count, 90)
            XCTAssertFalse(excerpt.songTitle.isEmpty)
            XCTAssertFalse(excerpt.artist.isEmpty)
        }
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 12,
        _ minute: Int = 0
    ) -> Date {
        makeDate(
            year,
            month,
            day,
            hour,
            minute,
            timeZoneID: hongKongTimeZone.identifier
        )
    }
}
