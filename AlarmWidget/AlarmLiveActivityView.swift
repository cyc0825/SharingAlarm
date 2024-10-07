//
//  AlarmLiveActivityView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/15.
//

import SwiftUI
import ActivityKit
import WidgetKit

//struct AlarmLiveActivityView: View {
//    let context: ActivityViewContext<AlarmAttributes>
//
//    var body: some View {
//        VStack {
//            Text("Alarm: \(context.attributes.alarmBody)")
//                .font(.headline)
//                .padding()
//                .foregroundStyle(Color.accent)
//
//            Text("Time Remaining: \(formatTime(context.state.remainingTime))")
//                .font(.largeTitle)
//                .bold()
//                .padding()
//                .foregroundStyle(Color.accent)
//        }
//        .activitySystemActionForegroundColor(.primary)
//    }
//
//    private func formatTime(_ remainingTime: TimeInterval) -> String {
//        let minutes = Int(remainingTime) / 60 % 60
//        let seconds = Int(remainingTime) % 60
//        return String(format: "%02i:%02i", minutes, seconds)
//    }
//}
