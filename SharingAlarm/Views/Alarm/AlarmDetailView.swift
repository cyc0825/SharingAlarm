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
    let alarm: Alarm
    
    var body: some View {
        VStack {
            HStack {
                Text("Alarm Time")
                Spacer()
                Text("\(alarm.time.formatted(date: .numeric, time: .standard))")
            }
            .padding()
            HStack {
                Text("Alarm Sound")
                Spacer()
                Text("\(alarm.sound)")
            }
            .padding()
            HStack {
                Text("Alarm Repeat")
                Spacer()
                Text("\(alarm.repeatInterval)")
            }
            .padding()
            HStack {
                Text("Activity")
                Spacer()
                
            }
            .padding()
        }
        .padding()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

