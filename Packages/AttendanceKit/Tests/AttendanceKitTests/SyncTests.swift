import Foundation
import XCTest
@testable import AttendanceKit

final class SyncTests: XCTestCase {
    func testWatchCommandClockInNowIsIdempotent() async {
        let queue = InMemoryWatchCommandQueue()
        let service = WatchSyncService(queue: queue)
        let id = UUID()
        let command = WatchCommand.clockInNow(commandID: id)
        let shouldProcessFirstCommand = await service.shouldProcess(command)
        let shouldProcessDuplicateCommand = await service.shouldProcess(command)
        XCTAssertTrue(shouldProcessFirstCommand)
        XCTAssertFalse(shouldProcessDuplicateCommand)
    }

    func testUnreachableFallbackQueuesCommand() async {
        let queue = InMemoryWatchCommandQueue()
        let service = WatchSyncService(queue: queue)
        let command = WatchCommand.clockOut(makeDate(2026, 7, 6, 17), commandID: UUID())
        await service.queueForFallback(command)
        let commands = await queue.commands
        XCTAssertEqual(commands, [command])
    }

    func testSeededProcessedCommandRemainsIdempotent() async {
        let id = UUID()
        let service = WatchSyncService(
            queue: InMemoryWatchCommandQueue(),
            processedCommandIDs: [id]
        )

        let shouldProcess = await service.shouldProcess(.clockInNow(commandID: id))

        XCTAssertFalse(shouldProcess)
    }

    func testSnapshotMessageCodecRoundTrip() throws {
        let now = makeDate(2026, 8, 11, 9)
        let target = makeDate(2026, 8, 11, 17)
        let record = AttendanceRecord(
            dayKey: "2026-08-11",
            clockInAt: now,
            targetEndAt: target,
            createdAt: now,
            updatedAt: now,
            sourceDevice: "Apple Watch"
        )
        let widgetSnapshot = AttendanceWidgetSnapshot(
            generatedAt: now,
            dayKey: "2026-08-11",
            isWorkday: true,
            hasClockIn: true,
            clockInAt: now,
            targetEndAt: target,
            status: .working,
            validAttendanceDays: 1,
            requiredDays: 17,
            totalWorkdays: 21,
            remainingNeeded: 16,
            monthPassed: false,
            monthLabel: "2026年8月",
            nextRefreshAt: target
        )
        let message = WatchSyncMessage.snapshot(
            WatchSyncSnapshot(
                generatedAt: now,
                records: [WatchAttendanceRecord(record: record)],
                widgetSnapshot: widgetSnapshot
            )
        )

        let decoded = try WatchSyncCodec.decode(WatchSyncCodec.encode(message))

        XCTAssertEqual(decoded, message)
    }
}
