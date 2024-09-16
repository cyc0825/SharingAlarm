//
//  AlarmWidget.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/15.
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct AlarmWidget: WidgetBundle {
    var body: some Widget {
        AlarmLiveActivity()
    }
}

struct AlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes.self) { context in
            AlarmLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    AlarmLiveActivityView(context: context)
                }
            } compactLeading: {
                Text("⏰")
            } compactTrailing: {
                Text("Time")
            } minimal: {
                Text("⏰")
            }
            .keylineTint(.yellow)
        }
    }
}
