import Foundation

public struct WidgetTimelineRenderState: Sendable, Equatable {
    public let snapshot: AttendanceWidgetSnapshot
    public let nextRefreshDate: Date

    public init(snapshot: AttendanceWidgetSnapshot, nextRefreshDate: Date) {
        self.snapshot = snapshot
        self.nextRefreshDate = nextRefreshDate
    }
}

public struct WidgetTimelineLogic: Sendable {
    public init() {}

    public func renderState(
        snapshot: AttendanceWidgetSnapshot,
        now: Date,
        calendar: WorkdayCalendar,
        policy: AttendancePolicy = .default
    ) -> WidgetTimelineRenderState {
        WidgetTimelineRenderState(
            snapshot: snapshot,
            nextRefreshDate: nextRefreshDate(snapshot: snapshot, now: now, calendar: calendar, policy: policy)
        )
    }

    public func nextRefreshDate(
        snapshot: AttendanceWidgetSnapshot,
        now: Date,
        calendar: WorkdayCalendar,
        policy: AttendancePolicy = .default
    ) -> Date {
        var candidates: [Date] = [
            calendar.nextStartOfDay(after: now),
            calendar.nextMonthBoundary(after: now),
            snapshot.nextRefreshAt
        ]

        if let targetEndAt = snapshot.targetEndAt, targetEndAt > now {
            candidates.append(targetEndAt)
        }

        if !snapshot.isWorkday {
            candidates.append(calendar.nextWorkday(after: now, policy: policy))
        }

        return candidates.filter { $0 > now }.min() ?? now.addingTimeInterval(15 * 60)
    }
}
