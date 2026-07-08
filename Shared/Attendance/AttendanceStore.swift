import AttendanceKit
import Foundation
import Observation
import SwiftData

#if canImport(WidgetKit)
import WidgetKit
#endif

#if os(iOS)
import UIKit
#endif

#if os(watchOS) && canImport(WatchKit)
import WatchKit
#endif

@MainActor
@Observable
final class AttendanceStore {
    static let shared = AttendanceStore()

    private(set) var records: [AttendanceRecord] = []
    private(set) var lastErrorMessage: String?

    private var modelContext: ModelContext?
    private let engine = AttendanceEngine()
    private let resolver = AttendanceConflictResolver()

    let policy = AttendancePolicy.default
    let workdayCalendar = WorkdayCalendar(timeZone: .current)

    private init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        load()
        refreshSnapshotAndWidgets()
    }

    func load() {
        guard let modelContext else { return }
        do {
            let descriptor = FetchDescriptor<AttendanceStorageRecord>(
                sortBy: [SortDescriptor(\.clockInAt, order: .reverse)]
            )
            let storageRecords = try modelContext.fetch(descriptor)
            records = resolver.canonicalRecords(from: storageRecords.map { $0.domainRecord() })
            lastErrorMessage = nil
        } catch {
            records = []
            lastErrorMessage = "无法读取打卡记录：\(error.localizedDescription)"
            log(lastErrorMessage ?? "Attendance load failed", prefix: "persistence")
        }
    }

    func todayRecord(now: Date = Date()) -> AttendanceRecord? {
        let todayKey = workdayCalendar.dayKey(for: now)
        return records.first { $0.dayKey == todayKey }
    }

    func status(for record: AttendanceRecord?, now: Date = Date()) -> AttendanceStatus {
        engine.status(record: record, now: now, policy: policy, calendar: workdayCalendar)
    }

    func remainingDuration(for record: AttendanceRecord, now: Date = Date()) -> TimeInterval {
        engine.remainingDuration(record: record, now: now)
    }

    func dailyProgress(for record: AttendanceRecord, now: Date = Date()) -> Double {
        engine.dailyProgress(record: record, now: now, policy: policy)
    }

    func monthProgress(containing date: Date = Date(), now: Date = Date()) -> MonthProgress {
        engine.monthProgress(
            monthContaining: date,
            records: records,
            now: now,
            policy: policy,
            calendar: workdayCalendar
        )
    }

    func clockInNow() {
        clockIn(at: Date(), isManual: false)
    }

    func clockIn(at clockInAt: Date, isManual: Bool) {
        guard clockInAt <= Date() else {
            lastErrorMessage = "打卡时间不能晚于当前时间。"
            return
        }
        let now = Date()
        let dayKey = workdayCalendar.dayKey(for: clockInAt)
        let record = AttendanceRecord(
            dayKey: dayKey,
            clockInAt: clockInAt,
            targetEndAt: engine.targetEnd(for: clockInAt, policy: policy),
            createdAt: now,
            updatedAt: now,
            sourceDevice: AttendanceDeviceName.current,
            isManualClockIn: isManual
        )
        upsert(record)
    }

    func update(record: AttendanceRecord, clockInAt: Date, actualClockOutAt: Date?) {
        guard clockInAt <= Date() else {
            lastErrorMessage = "打卡时间不能晚于当前时间。"
            return
        }
        if let actualClockOutAt, actualClockOutAt < clockInAt {
            lastErrorMessage = "下班时间不能早于上班时间。"
            return
        }
        record.clockInAt = clockInAt
        record.dayKey = workdayCalendar.dayKey(for: clockInAt)
        record.targetEndAt = engine.targetEnd(for: clockInAt, policy: policy)
        record.actualClockOutAt = actualClockOutAt
        record.updatedAt = Date()
        record.isManualClockIn = true
        upsert(record)
    }

    func clockOut(record: AttendanceRecord, at clockOutAt: Date = Date()) {
        record.actualClockOutAt = clockOutAt
        record.updatedAt = Date()
        upsert(record)
    }

    func delete(record: AttendanceRecord) {
        guard let modelContext else { return }
        do {
            let id = record.id
            let descriptor = FetchDescriptor<AttendanceStorageRecord>(
                predicate: #Predicate { $0.id == id }
            )
            for storageRecord in try modelContext.fetch(descriptor) {
                modelContext.delete(storageRecord)
            }
            try modelContext.save()
            load()
            refreshSnapshotAndWidgets()
        } catch {
            lastErrorMessage = "删除失败：\(error.localizedDescription)"
            log(lastErrorMessage ?? "Attendance delete failed", prefix: "persistence")
        }
    }

    func refreshSnapshotAndWidgets() {
        let snapshot = makeSnapshot(now: Date())
        do {
            try WidgetSnapshotStore.write(snapshot)
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: "com.tsubuzaki.WorkingHour.Ushio.Home")
            #endif
        } catch {
            lastErrorMessage = "Widget 快照更新失败：\(error.localizedDescription)"
            log(lastErrorMessage ?? "Snapshot write failed", prefix: "widget")
        }
    }

    private func upsert(_ record: AttendanceRecord) {
        guard let modelContext else { return }
        do {
            let dayKey = record.dayKey
            let descriptor = FetchDescriptor<AttendanceStorageRecord>(
                predicate: #Predicate { $0.dayKey == dayKey }
            )
            let matches = try modelContext.fetch(descriptor)
            if let existing = resolverStorageRecord(from: matches) {
                existing.apply(record)
                for duplicate in matches where duplicate.id != existing.id {
                    modelContext.delete(duplicate)
                }
            } else {
                modelContext.insert(AttendanceStorageRecord(record: record))
            }
            try modelContext.save()
            load()
            refreshSnapshotAndWidgets()
        } catch {
            lastErrorMessage = "保存失败：\(error.localizedDescription)"
            log(lastErrorMessage ?? "Attendance upsert failed", prefix: "persistence")
        }
    }

    private func resolverStorageRecord(from records: [AttendanceStorageRecord]) -> AttendanceStorageRecord? {
        records.sorted {
            if $0.updatedAt != $1.updatedAt {
                return $0.updatedAt < $1.updatedAt
            }
            return $0.id.uuidString < $1.id.uuidString
        }.last
    }

    private func makeSnapshot(now: Date) -> AttendanceWidgetSnapshot {
        let today = todayRecord(now: now)
        let progress = monthProgress(containing: now, now: now)
        let status = status(for: today, now: now)
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "zh_Hans_CN")
        monthFormatter.dateFormat = "yyyy年M月"
        let targetEndAt = today?.targetEndAt

        return AttendanceWidgetSnapshot(
            generatedAt: now,
            dayKey: workdayCalendar.dayKey(for: now),
            isWorkday: workdayCalendar.isWorkday(now, policy: policy),
            hasClockIn: today != nil,
            clockInAt: today?.clockInAt,
            targetEndAt: targetEndAt,
            status: status,
            validAttendanceDays: progress.validAttendanceDays,
            requiredDays: progress.requiredDays,
            totalWorkdays: progress.totalWorkdays,
            remainingNeeded: progress.remainingNeeded,
            monthPassed: progress.passed,
            monthLabel: monthFormatter.string(from: now),
            nextRefreshAt: workdayCalendar.nextMeaningfulRefreshDate(now: now, targetEndAt: targetEndAt, policy: policy)
        )
    }
}

private enum AttendanceDeviceName {
    static var current: String {
        #if os(iOS)
        UIDevice.current.name
        #elseif os(watchOS) && canImport(WatchKit)
        WKInterfaceDevice.current().name
        #elseif os(macOS)
        Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        #else
        ProcessInfo.processInfo.hostName
        #endif
    }
}
