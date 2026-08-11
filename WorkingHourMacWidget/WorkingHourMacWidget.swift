import SwiftUI
import WidgetKit

@main
struct WorkingHourMacWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkingHourMacWidget()
    }
}

struct WorkingHourMacWidget: Widget {
    private let kind = "com.tsubuzaki.WorkingHour.Mac.Attendance"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeWidgetProvider()) { entry in
            HomeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("打卡倒计时")
        .description("显示今天的打卡状态与本月进度。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
