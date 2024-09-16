//
//  AlarmAttributes.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/15.
//

import Foundation
import ActivityKit

struct AlarmAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingTime: TimeInterval
        var alarmBody: String
    }

    var alarmTime: Date
    var alarmBody: String
}
