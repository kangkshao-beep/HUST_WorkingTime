//
//  HomeWidgetView.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2026/02/20.
//

import AttendanceKit
import SwiftUI
import WidgetKit

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: HomeWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryInline:
            inlineWidget
        case .accessoryCircular:
            circularWidget
        case .accessoryRectangular:
            rectangularWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(statusTitle, systemImage: statusIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)

            Spacer(minLength: 4)

            if entry.snapshot.status == .working, let targetEndAt = entry.snapshot.targetEndAt {
                Text("距离下班")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(targetEndAt, style: .timer)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
            } else {
                Text(statusTitle)
                    .font(.headline.weight(.bold))
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 4)

            Text("本月 \(entry.snapshot.validAttendanceDays)/\(entry.snapshot.requiredDays)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "workdaycountdown://today"))
    }

    private var mediumWidget: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Label(statusTitle, systemImage: statusIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                if entry.snapshot.status == .working, let targetEndAt = entry.snapshot.targetEndAt {
                    Text(targetEndAt, style: .timer)
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                        .minimumScaleFactor(0.65)
                } else {
                    Text(statusTitle)
                        .font(.title2.weight(.bold))
                        .minimumScaleFactor(0.75)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if let clockInAt = entry.snapshot.clockInAt {
                    Text("上班")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(clockInAt, style: .time)
                        .font(.headline)
                }
                if let targetEndAt = entry.snapshot.targetEndAt {
                    Text("预计下班")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(targetEndAt, style: .time)
                        .font(.headline)
                }
                Text("本月 \(entry.snapshot.validAttendanceDays)/\(entry.snapshot.requiredDays)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.snapshot.monthPassed ? .green : .secondary)
            }
        }
        .widgetURL(URL(string: "workdaycountdown://today"))
    }



    private var inlineWidget: some View {
        if entry.snapshot.status == .working, let targetEndAt = entry.snapshot.targetEndAt {
            Text("下班 \(targetEndAt.formatted(date: .omitted, time: .shortened))")
        } else {
            Text(statusTitle)
        }
    }

    private var circularWidget: some View {
        Gauge(value: dayProgress) {
            Image(systemName: statusIcon)
        } currentValueLabel: {
            Text(circularLabel)
                .font(.caption2.weight(.bold))
                .minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var rectangularWidget: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(statusTitle)
                .font(.headline)
            if entry.snapshot.status == .working, let targetEndAt = entry.snapshot.targetEndAt {
                Text(targetEndAt, style: .timer)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
            }
            Text("本月 \(entry.snapshot.validAttendanceDays)/\(entry.snapshot.requiredDays)")
                .font(.caption2)
        }
    }


    private var statusTitle: String {
        switch entry.snapshot.status {
        case .weekend:
            return "今天休息"
        case .notClockedIn:
            return "今天尚未打卡"
        case .working:
            return "工作中"
        case .targetReached:
            return "8 小时完成"
        case .clockedOutEarly:
            return "已提前结束"
        case .completed:
            return "今天已完成"
        }
    }

    private var statusIcon: String {
        switch entry.snapshot.status {
        case .weekend:
            return "moon.zzz.fill"
        case .notClockedIn:
            return "clock.badge.exclamationmark"
        case .working:
            return "timer"
        case .targetReached, .completed:
            return "checkmark.circle.fill"
        case .clockedOutEarly:
            return "exclamationmark.circle.fill"
        }
    }


    private var dayProgress: Double {
        guard let clockInAt = entry.snapshot.clockInAt,
              let targetEndAt = entry.snapshot.targetEndAt else {
            return entry.snapshot.monthPassed ? 1 : 0
        }
        let total = targetEndAt.timeIntervalSince(clockInAt)
        guard total > 0 else { return 1 }
        return min(max(Date().timeIntervalSince(clockInAt) / total, 0), 1)
    }

    private var circularLabel: String {
        if entry.snapshot.status == .targetReached || entry.snapshot.status == .completed {
            return "OK"
        }
        if let targetEndAt = entry.snapshot.targetEndAt {
            let hours = max(Int(ceil(targetEndAt.timeIntervalSince(Date()) / 3600)), 0)
            return "\(hours)h"
        }
        return "--"
    }

    private var statusColor: Color {
        switch entry.snapshot.status {
        case .weekend, .notClockedIn:
            return .secondary
        case .working:
            return .blue
        case .targetReached, .completed:
            return .green
        case .clockedOutEarly:
            return .orange
        }
    }
}
