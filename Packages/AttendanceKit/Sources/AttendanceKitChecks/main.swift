import AttendanceKit
import Foundation

struct CheckFailure: Error, CustomStringConvertible {
    let message: String

    var description: String {
        message
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw CheckFailure(message: message)
    }
}

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
        sourceDevice: "check"
    )
}

func checkWorkdayCalendar() throws {
    let calendar = makeCalendar()
    try expect(calendar.isWorkday(makeDate(2026, 7, 6)), "Monday should be a workday")
    try expect(calendar.isWorkday(makeDate(2026, 7, 10)), "Friday should be a workday")
    try expect(!calendar.isWorkday(makeDate(2026, 7, 11)), "Saturday should not be a workday")
    try expect(!calendar.isWorkday(makeDate(2026, 7, 12)), "Sunday should not be a workday")
    try expect(calendar.weekdaysInMonth(containing: makeDate(2026, 2, 1)).count == 20, "February 2026 should have 20 weekdays")
    try expect(calendar.weekdaysInMonth(containing: makeDate(2024, 2, 1)).count == 21, "February 2024 should have 21 weekdays")
    try expect(calendar.weekdaysInMonth(containing: makeDate(2025, 9, 1)).count == 22, "September 2025 should have 22 weekdays")
    try expect(calendar.weekdaysInMonth(containing: makeDate(2026, 7, 1)).count == 23, "July 2026 should have 23 weekdays")
    try expect(calendar.dayKey(for: makeDate(2026, 7, 6, 0, 30)) == "2026-07-06", "Shanghai dayKey should be stable")
    try expect(makeCalendar("America/Los_Angeles").dayKey(for: makeDate(2026, 7, 6, 0, 30)) == "2026-07-05", "Los Angeles dayKey should reflect injected timezone")
}

func checkRequiredAttendance() throws {
    let engine = AttendanceEngine()
    let calendar = makeCalendar()
    try expect(engine.monthProgress(monthContaining: makeDate(2026, 2, 1), records: [], now: makeDate(2026, 2, 1), calendar: calendar).requiredDays == 16, "20 weekdays should require 16 days")
    try expect(engine.monthProgress(monthContaining: makeDate(2026, 8, 1), records: [], now: makeDate(2026, 8, 1), calendar: calendar).requiredDays == 17, "21 weekdays should require 17 days")
    try expect(engine.monthProgress(monthContaining: makeDate(2025, 9, 1), records: [], now: makeDate(2025, 9, 1), calendar: calendar).requiredDays == 18, "22 weekdays should require 18 days")
    try expect(engine.monthProgress(monthContaining: makeDate(2026, 7, 1), records: [], now: makeDate(2026, 7, 1), calendar: calendar).requiredDays == 19, "23 weekdays should require 19 days")
}

func checkAttendanceEngine() throws {
    let engine = AttendanceEngine()
    let calendar = makeCalendar()
    let record = makeRecord(2026, 7, 6)
    try expect(engine.status(record: nil, now: makeDate(2026, 7, 6, 9), calendar: calendar) == .notClockedIn, "No record should be notClockedIn")
    try expect(engine.status(record: nil, now: makeDate(2026, 7, 11, 9), calendar: calendar) == .weekend, "Weekend should be weekend status")
    try expect(engine.targetEnd(for: makeDate(2026, 7, 6, 9)) == makeDate(2026, 7, 6, 17), "09:00 should target 17:00")
    try expect(abs(engine.remainingDuration(record: record, now: makeDate(2026, 7, 6, 12)) - 5 * 60 * 60) <= 0.001, "Noon should have 5 hours remaining")
    try expect(engine.status(record: record, now: makeDate(2026, 7, 6, 17), calendar: calendar) == .targetReached, "Target time should be reached")
    try expect(engine.isDailyTargetMet(record: record, now: makeDate(2026, 7, 6, 17)), "Daily target should be met at targetEndAt")

    record.actualClockOutAt = makeDate(2026, 7, 6, 16)
    try expect(engine.status(record: record, now: makeDate(2026, 7, 6, 16), calendar: calendar) == .clockedOutEarly, "Early clock-out should be separate")
    try expect(engine.isValidAttendance(record: record, calendar: calendar), "Early clock-out still has valid attendance in MVP")
    try expect(!engine.isDailyTargetMet(record: record, now: makeDate(2026, 7, 6, 18)), "Early clock-out should not meet daily target")
}

func checkDuplicatesAndMonthProgress() throws {
    let resolver = AttendanceConflictResolver()
    let older = makeRecord(2026, 7, 6, updatedAt: makeDate(2026, 7, 6, 10))
    let newer = makeRecord(2026, 7, 6, hour: 8, updatedAt: makeDate(2026, 7, 6, 11))
    try expect(resolver.canonicalRecord(from: [older, newer])?.clockInAt == newer.clockInAt, "Newer updatedAt should win")

    let engine = AttendanceEngine()
    let progress = engine.monthProgress(
        monthContaining: makeDate(2026, 7, 15),
        records: [older, newer],
        now: makeDate(2026, 7, 15),
        calendar: makeCalendar()
    )
    try expect(progress.validAttendanceDays == 1, "Duplicate dayKey records should count once")
}

func checkWidgetTimeline() throws {
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
    try expect(WidgetTimelineLogic().nextRefreshDate(snapshot: snapshot, now: now, calendar: calendar) == target, "Active countdown should refresh at targetEndAt")
}

func checkWatchSync() async throws {
    let queue = InMemoryWatchCommandQueue()
    let service = WatchSyncService(queue: queue)
    let command = WatchCommand.clockInNow(commandID: UUID())
    let shouldProcessFirstCommand = await service.shouldProcess(command)
    try expect(shouldProcessFirstCommand, "First watch command should process")
    let shouldProcessDuplicateCommand = await service.shouldProcess(command)
    try expect(!shouldProcessDuplicateCommand, "Duplicate watch command should be ignored")
    await service.queueForFallback(command)
    let fallbackCommands = await queue.commands
    try expect(fallbackCommands == [command], "Fallback queue should store unreachable command")

    let encoded = try WatchSyncCodec.encode(.command(command))
    let decoded = try WatchSyncCodec.decode(encoded)
    try expect(decoded == .command(command), "Watch messages should round-trip through the codec")
}

do {
    try checkWorkdayCalendar()
    try checkRequiredAttendance()
    try checkAttendanceEngine()
    try checkDuplicatesAndMonthProgress()
    try checkWidgetTimeline()
    try await checkWatchSync()
    print("AttendanceKitChecks passed")
} catch {
    FileHandle.standardError.write(Data("AttendanceKitChecks failed: \(error)\n".utf8))
    Foundation.exit(1)
}
