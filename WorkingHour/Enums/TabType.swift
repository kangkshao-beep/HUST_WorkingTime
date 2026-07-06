//
//  TabType.swift
//  Working Hour
//
//  Created by シン・ジャスティン on 2024/11/04.
//

import Foundation
import Komponents

enum TabType: Int, TabTypeProtocol {
    case today = 0
    case month = 1
    case history = 2
    case settings = 3

    static var defaultTab: TabType = .today
}
