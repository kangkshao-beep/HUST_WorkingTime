import Foundation

public enum WatchCommand: Codable, Sendable, Equatable {
    case requestSnapshot
    case clockInNow(commandID: UUID)
    case clockInAt(Date, commandID: UUID)
    case clockOut(Date, commandID: UUID)
}

public struct WatchAttendanceRecord: Codable, Sendable, Equatable {
    public let id: UUID
    public let dayKey: String
    public let clockInAt: Date
    public let targetEndAt: Date
    public let actualClockOutAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    public let sourceDevice: String
    public let isManualClockIn: Bool

    public init(record: AttendanceRecord) {
        id = record.id
        dayKey = record.dayKey
        clockInAt = record.clockInAt
        targetEndAt = record.targetEndAt
        actualClockOutAt = record.actualClockOutAt
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        sourceDevice = record.sourceDevice
        isManualClockIn = record.isManualClockIn
    }

    public func domainRecord() -> AttendanceRecord {
        AttendanceRecord(
            id: id,
            dayKey: dayKey,
            clockInAt: clockInAt,
            targetEndAt: targetEndAt,
            actualClockOutAt: actualClockOutAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceDevice: sourceDevice,
            isManualClockIn: isManualClockIn
        )
    }
}

public struct WatchSyncSnapshot: Codable, Sendable, Equatable {
    public let generatedAt: Date
    public let records: [WatchAttendanceRecord]
    public let widgetSnapshot: AttendanceWidgetSnapshot

    public init(
        generatedAt: Date,
        records: [WatchAttendanceRecord],
        widgetSnapshot: AttendanceWidgetSnapshot
    ) {
        self.generatedAt = generatedAt
        self.records = records
        self.widgetSnapshot = widgetSnapshot
    }
}

public enum WatchSyncMessage: Codable, Sendable, Equatable {
    case command(WatchCommand)
    case snapshot(WatchSyncSnapshot)
}

public enum WatchSyncCodec {
    public static func encode(_ message: WatchSyncMessage) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(message)
    }

    public static func decode(_ data: Data) throws -> WatchSyncMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WatchSyncMessage.self, from: data)
    }
}

public protocol WatchCommandQueueing: Sendable {
    func enqueue(_ command: WatchCommand) async
}

public actor InMemoryWatchCommandQueue: WatchCommandQueueing {
    public private(set) var commands: [WatchCommand] = []

    public init() {}

    public func enqueue(_ command: WatchCommand) async {
        commands.append(command)
    }
}

public actor WatchSyncService {
    private var processedCommandIDs: Set<UUID> = []
    private let queue: WatchCommandQueueing

    public init(
        queue: WatchCommandQueueing,
        processedCommandIDs: Set<UUID> = []
    ) {
        self.queue = queue
        self.processedCommandIDs = processedCommandIDs
    }

    public func shouldProcess(_ command: WatchCommand) -> Bool {
        guard let id = command.commandID else {
            return true
        }
        if processedCommandIDs.contains(id) {
            return false
        }
        processedCommandIDs.insert(id)
        return true
    }

    public func queueForFallback(_ command: WatchCommand) async {
        await queue.enqueue(command)
    }
}

public extension WatchCommand {
    var commandID: UUID? {
        switch self {
        case .requestSnapshot:
            return nil
        case .clockInNow(let commandID):
            return commandID
        case .clockInAt(_, let commandID):
            return commandID
        case .clockOut(_, let commandID):
            return commandID
        }
    }
}
