//
//  HomeWidgetProvider.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2026/02/20.
//

import AttendanceKit
import Foundation
import SwiftUI
import WidgetKit

struct HomeWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: AttendanceWidgetSnapshot

    static var placeholder: HomeWidgetEntry {
        let calendar = WorkdayCalendar(timeZone: .current)
        let now = Date()
        return HomeWidgetEntry(
            date: now,
            snapshot: AttendanceWidgetSnapshot(
                generatedAt: now,
                dayKey: calendar.dayKey(for: now),
                isWorkday: true,
                hasClockIn: true,
                clockInAt: calendar.calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now),
                targetEndAt: calendar.calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now),
                status: .working,
                validAttendanceDays: 14,
                requiredDays: 18,
                totalWorkdays: 22,
                remainingNeeded: 4,
                monthPassed: false,
                monthLabel: String(localized: "本月", table: "Widget"),
                nextRefreshAt: calendar.nextMeaningfulRefreshDate(now: now)
            )
        )
    }

    static var empty: HomeWidgetEntry {
        let calendar = WorkdayCalendar(timeZone: .current)
        let now = Date()
        return HomeWidgetEntry(
            date: now,
            snapshot: AttendanceWidgetSnapshot(
                generatedAt: now,
                dayKey: calendar.dayKey(for: now),
                isWorkday: calendar.isWorkday(now),
                hasClockIn: false,
                clockInAt: nil,
                targetEndAt: nil,
                status: calendar.isWorkday(now) ? .notClockedIn : .weekend,
                validAttendanceDays: 0,
                requiredDays: 0,
                totalWorkdays: 0,
                remainingNeeded: 0,
                monthPassed: false,
                monthLabel: String(localized: "本月", table: "Widget"),
                nextRefreshAt: calendar.nextMeaningfulRefreshDate(now: now)
            )
        )
    }
}

struct HomeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomeWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder : fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeWidgetEntry>) -> Void) {
        let entry = fetchEntry()
        let logic = WidgetTimelineLogic()
        let calendar = WorkdayCalendar(timeZone: .current)
        let refreshDate = logic.nextRefreshDate(snapshot: entry.snapshot, now: Date(), calendar: calendar)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func fetchEntry() -> HomeWidgetEntry {
        let snapshot = WidgetSnapshotStore.read() ?? HomeWidgetEntry.empty.snapshot
        return HomeWidgetEntry(date: Date(), snapshot: snapshot)
    }
}
