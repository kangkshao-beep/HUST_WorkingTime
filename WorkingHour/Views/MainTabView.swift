//
//  MainTabView.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/11/04.
//

import Komponents
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var navigator: Navigator<TabType, ViewPath>

    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            Tab("今天", systemImage: "clock.badge.checkmark", value: .today) {
                AttendanceTodayView()
            }
            Tab("本月", systemImage: "calendar", value: .month) {
                AttendanceMonthView()
            }
            Tab("历史", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90", value: .history) {
                AttendanceHistoryView()
            }
            Tab("设置", systemImage: "gearshape", value: .settings) {
                AttendanceSettingsView()
            }
        }
        .tint(AttendanceTheme.accent)
        .toolbarBackground(.white.opacity(0.9), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
