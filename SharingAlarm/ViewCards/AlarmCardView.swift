//
//  AlarmCardView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/11.
//

import SwiftUI

struct AlarmCardView: View {
    @StateObject var viewModel = AlarmsViewModel()
    @Binding var alarm: Alarm
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(alarm.time.formatted(date: .omitted, time: .shortened))")
                        .font(.title)
                        .foregroundColor(alarm.isOn ? .systemText : .gray)
                    Text("\(alarm.time.formatted(date: .complete, time: .omitted))")
                        .foregroundColor(alarm.isOn ? .systemText : .gray)
                }
                Spacer()
                Toggle(isOn: $alarm.isOn){
                    Text("")
                }
                .tint(.accent)
                .labelsHidden()
            }
            .onChange(of: alarm.isOn) {
                if let alarmId = alarm.id {
                    viewModel.toggleAlarm(alarmId: alarmId, value: alarm.isOn)
                    if alarm.isOn {
                        AppDelegate.shared.scheduleLocalNotification(id: alarmId, title: "Alarm Notification", body: "Rescheduled Alarm", alarmTime: alarm.time, sound: alarm.sound)
                    } else {
                        AppDelegate.shared.cancelScheduledLocalNotification(id: alarmId)
                    }
                }
            }
        }
    }
}
