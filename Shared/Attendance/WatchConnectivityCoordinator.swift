#if os(iOS) || os(watchOS)
import AttendanceKit
import Foundation
import WatchConnectivity

final class WatchConnectivityCoordinator: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityCoordinator()

    private enum PayloadKey {
        static let data = "attendanceSyncPayload"
    }

    private let session: WCSession
    private let syncService: WatchSyncService

    private override init() {
        session = .default
        syncService = WatchSyncService(
            queue: InMemoryWatchCommandQueue(),
            processedCommandIDs: WatchCommandHistory.processedIDs
        )
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    func requestSnapshot() {
        transmit(.command(.requestSnapshot))
    }

    func send(command: WatchCommand) {
        transmit(.command(command))
    }

    func publish(snapshot: WatchSyncSnapshot) {
        guard session.activationState == .activated else { return }
        do {
            try session.updateApplicationContext(try payload(for: .snapshot(snapshot)))
        } catch {
            log("Unable to publish watch snapshot: \(error.localizedDescription)", prefix: "watch-sync")
        }
    }

    private func transmit(_ message: WatchSyncMessage) {
        guard session.activationState == .activated else {
            if case .command(let command) = message {
                enqueue(command)
            }
            return
        }

        do {
            let payload = try payload(for: message)
            if session.isReachable {
                session.sendMessage(payload) { [weak self] reply in
                    self?.receive(reply)
                } errorHandler: { [weak self] error in
                    log("Immediate watch message failed: \(error.localizedDescription)", prefix: "watch-sync")
                    self?.enqueue(message)
                }
            } else {
                enqueue(message)
            }
        } catch {
            log("Unable to encode watch message: \(error.localizedDescription)", prefix: "watch-sync")
        }
    }

    private func enqueue(_ command: WatchCommand) {
        enqueue(.command(command))
    }

    private func enqueue(_ message: WatchSyncMessage) {
        do {
            session.transferUserInfo(try payload(for: message))
        } catch {
            log("Unable to queue watch message: \(error.localizedDescription)", prefix: "watch-sync")
        }
    }

    private func payload(for message: WatchSyncMessage) throws -> [String: Any] {
        [PayloadKey.data: try WatchSyncCodec.encode(message)]
    }

    private func receive(
        _ payload: [String: Any],
        replyHandler: (([String: Any]) -> Void)? = nil
    ) {
        guard let data = payload[PayloadKey.data] as? Data else { return }

        do {
            let message = try WatchSyncCodec.decode(data)
            Task { @MainActor [weak self] in
                await self?.handle(message, replyHandler: replyHandler)
            }
        } catch {
            log("Unable to decode watch message: \(error.localizedDescription)", prefix: "watch-sync")
        }
    }

    @MainActor
    private func handle(
        _ message: WatchSyncMessage,
        replyHandler: (([String: Any]) -> Void)?
    ) async {
        switch message {
        case .command(let command):
            #if os(iOS)
            if await syncService.shouldProcess(command) {
                WatchCommandHistory.record(command.commandID)
                AttendanceStore.shared.applyWatchCommand(command)
            }

            let snapshot = AttendanceStore.shared.makeWatchSyncSnapshot()
            if let replyHandler,
               let reply = try? payload(for: .snapshot(snapshot)) {
                replyHandler(reply)
            }
            publish(snapshot: snapshot)
            #endif

        case .snapshot(let snapshot):
            #if os(watchOS)
            AttendanceStore.shared.mergeWatchSyncSnapshot(snapshot)
            #endif
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            log("WatchConnectivity activation failed: \(error.localizedDescription)", prefix: "watch-sync")
            return
        }

        guard activationState == .activated else { return }
        Task { @MainActor [weak self] in
            #if os(iOS)
            self?.publish(snapshot: AttendanceStore.shared.makeWatchSyncSnapshot())
            #elseif os(watchOS)
            self?.requestSnapshot()
            #endif
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        receive(message, replyHandler: replyHandler)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        receive(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receive(applicationContext)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}

private enum WatchCommandHistory {
    private static let key = "attendance.watch.processed-command-ids"
    private static let maximumCount = 256

    static var processedIDs: Set<UUID> {
        Set(
            UserDefaults.standard.stringArray(forKey: key)?
                .compactMap(UUID.init(uuidString:)) ?? []
        )
    }

    static func record(_ id: UUID?) {
        guard let id else { return }
        var values = UserDefaults.standard.stringArray(forKey: key) ?? []
        let value = id.uuidString
        guard !values.contains(value) else { return }
        values.append(value)
        UserDefaults.standard.set(Array(values.suffix(maximumCount)), forKey: key)
    }
}
#endif
