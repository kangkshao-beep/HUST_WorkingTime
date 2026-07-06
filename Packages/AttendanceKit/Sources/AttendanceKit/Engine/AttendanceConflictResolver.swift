import Foundation

public struct AttendanceConflictResolver: Sendable {
    public init() {}

    public func canonicalRecord(from records: [AttendanceRecord]) -> AttendanceRecord? {
        records.sorted(by: isPreferred(lhs:rhs:)).last
    }

    public func canonicalRecords(from records: [AttendanceRecord]) -> [AttendanceRecord] {
        Dictionary(grouping: records, by: \.dayKey)
            .compactMap { _, grouped in canonicalRecord(from: grouped) }
            .sorted { $0.dayKey < $1.dayKey }
    }

    private func isPreferred(lhs: AttendanceRecord, rhs: AttendanceRecord) -> Bool {
        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt < rhs.updatedAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
