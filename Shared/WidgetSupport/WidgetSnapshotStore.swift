import AttendanceKit
import Foundation

enum WidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.tsubuzaki.WorkingHour"
    static let snapshotFilename = "attendance-widget-snapshot.json"

    private static var isAppGroupEnabled: Bool {
        Bundle.main.object(forInfoDictionaryKey: "AttendanceAppGroupEnabled") as? Bool == true
    }

    static func write(_ snapshot: AttendanceWidgetSnapshot) throws {
        guard isAppGroupEnabled else { return }
        let url = try snapshotURL(createDirectory: true)
        let data = try JSONEncoder.attendanceSnapshotEncoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }

    static func read() -> AttendanceWidgetSnapshot? {
        guard isAppGroupEnabled,
              let url = try? snapshotURL(createDirectory: false),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder.attendanceSnapshotDecoder.decode(AttendanceWidgetSnapshot.self, from: data)
    }

    private static func snapshotURL(createDirectory: Bool) throws -> URL {
        let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = baseURL.appendingPathComponent("AttendanceWidget", isDirectory: true)
        if createDirectory {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent(snapshotFilename)
    }
}

private extension JSONEncoder {
    static var attendanceSnapshotEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var attendanceSnapshotDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
