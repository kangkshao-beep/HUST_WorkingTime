//
//  Controls.swift
//  Ushio
//
//  Created by シン・ジャスティン on 2024/12/09.
//

import SwiftUI
import WidgetKit

struct StartWorkSessionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.tsubuzaki.WorkingHour.Ushio.Start"
        ) {
            ControlWidgetButton(action: StartWorkSessionIntent()) {
                Label(
                    String(localized: "TimeClock.Work.ClockIn", table: "Widget"),
                    systemImage: "figure.walk.arrival"
                )
            }
        }
        .displayName(LocalizedStringResource("TimeClock.Work.ClockIn", table: "Widget"))
        .description(LocalizedStringResource("TimeClock.Work.StartSession", table: "Widget"))
    }
}

struct EndWorkSessionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.tsubuzaki.WorkingHour.Ushio.End"
        ) {
            ControlWidgetButton(action: EndWorkSessionIntent()) {
                Label(
                    String(localized: "TimeClock.Work.ClockOut", table: "Widget"),
                    systemImage: "figure.walk.departure"
                )
            }
        }
        .displayName(LocalizedStringResource("TimeClock.Work.ClockOut", table: "Widget"))
        .description(LocalizedStringResource("TimeClock.Work.ClockOutSession", table: "Widget"))
    }
}
