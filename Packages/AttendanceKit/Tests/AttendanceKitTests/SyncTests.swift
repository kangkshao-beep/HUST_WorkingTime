import Foundation
import XCTest
@testable import AttendanceKit

final class SyncTests: XCTestCase {
    func testWatchCommandClockInNowIsIdempotent() async {
        let queue = InMemoryWatchCommandQueue()
        let service = WatchSyncService(queue: queue)
        let id = UUID()
        let command = WatchCommand.clockInNow(commandID: id)
        XCTAssertTrue(await service.shouldProcess(command))
        XCTAssertFalse(await service.shouldProcess(command))
    }

    func testUnreachableFallbackQueuesCommand() async {
        let queue = InMemoryWatchCommandQueue()
        let service = WatchSyncService(queue: queue)
        let command = WatchCommand.clockOut(makeDate(2026, 7, 6, 17), commandID: UUID())
        await service.queueForFallback(command)
        let commands = await queue.commands
        XCTAssertEqual(commands, [command])
    }
}
