import Foundation

public protocol AttendanceRepository: Sendable {
    func fetchAll() async throws -> [AttendanceRecord]
    func fetch(dayKey: String) async throws -> AttendanceRecord?
    func upsert(_ record: AttendanceRecord) async throws
    func delete(id: UUID) async throws
}
