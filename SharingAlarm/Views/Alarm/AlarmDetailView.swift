//
//  AlarmDetailView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/7.
//

import SwiftUI

import Firebase

struct AlarmDetailView: View {
    @StateObject var viewModel: AlarmsViewModel
    @State var sound: String = ""
    let alarm: Alarm
    var body: some View {
        VStack {
            Spacer()
            
            CountDownTimerView(viewModel: TimerViewModel(targetDate: alarm.time))
                .padding(.top, 50)
            Divider()
            
            HStack {
                Text("Alarm Time")
                Spacer()
                Text("\(alarm.time.formatted(date: .numeric, time: .standard))")
            }
            .padding()
            HStack {
                Text("Alarm Sound")
                Spacer()
                Text((alarm.sound == "YourRecording.m4a" ?
                      "\(alarm.creatorName ?? "Unknown")'s Recording" :
                        alarm.sound.components(separatedBy: ".").first) ?? alarm.sound)
            }
            .padding()
            HStack {
                Text("Alarm Repeat")
                Spacer()
                Text("\(alarm.repeatInterval)")
            }
            .padding()
            HStack {
                if let activityName = alarm.activityName {
                    Text("Activity")
                    Spacer()
                    Text(activityName)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .presentationDetents([.fraction(0.4), .large])
        .presentationDragIndicator(.visible)
    }
}
