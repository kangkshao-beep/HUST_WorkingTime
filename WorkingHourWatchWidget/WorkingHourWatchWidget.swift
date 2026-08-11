import SwiftUI
import WidgetKit

@main
struct WorkingHourWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkingHourWatchWidget()
    }
}

struct WorkingHourWatchWidget: Widget {
    private let kind = "com.tsubuzaki.WorkingHour.Watch.Attendance"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeWidgetProvider()) { entry in
            HomeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(String(localized: "打卡倒计时", table: "Widget"))
        .description(String(localized: "显示今天的打卡状态与本月进度。", table: "Widget"))
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
