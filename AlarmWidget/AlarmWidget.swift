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
                    VStack {
                        Text("Alarm: \(context.attributes.alarmBody)")
                            .font(.headline)
                            .foregroundStyle(Color.accent)

                        Text("Time Remaining: \(formatTime(context.state.remainingTime))")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(Color.accent)
                    }
                    .padding(.bottom)
                    .activitySystemActionForegroundColor(.primary)
                }
            } compactLeading: {
                Text("⏰")
            } compactTrailing: {
                Text("\(formatTime(context.state.remainingTime))")
            } minimal: {
                Text("⏰")
            }
            .keylineTint(.yellow)
        }
    }
    
    private func formatTime(_ remainingTime: TimeInterval) -> String {
        let minutes = Int(remainingTime) / 60 % 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
}
