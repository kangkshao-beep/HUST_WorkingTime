import Foundation

public enum WatchCommand: Codable, Sendable, Equatable {
    case requestSnapshot
    case clockInNow(commandID: UUID)
    case clockInAt(Date, commandID: UUID)
    case clockOut(Date, commandID: UUID)
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

    public init(queue: WatchCommandQueueing) {
        self.queue = queue
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
