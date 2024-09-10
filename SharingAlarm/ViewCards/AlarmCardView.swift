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
                        .foregroundColor(alarm.isOn ?? true ? .systemText : .gray)
                    Text("\(alarm.time.formatted(date: .complete, time: .omitted))")
                        .foregroundColor(alarm.isOn ?? true ? .systemText : .gray)
                }
                Spacer()
                Toggle(isOn: Binding(
                    get: { alarm.isOn ?? true },
                    set: { alarm.isOn = $0 }
                )) {
                    Text("")
                }
                .tint(.accent)
                .labelsHidden()
            }
            .onChange(of: alarm.isOn) {
                if let alarmId = alarm.id, let isOn = alarm.isOn {
                    viewModel.toggleAlarm(alarmId: alarmId, value: isOn)
                    if isOn {
                        AppDelegate.shared.scheduleLocalNotification(id: alarmId, title: "Alarm Notification", body: "Rescheduled Alarm", alarmTime: alarm.time, sound: alarm.sound, ringtoneURL: alarm.ringtoneURL)
                    } else {
                        AppDelegate.shared.cancelScheduledLocalNotification(id: alarmId)
                    }
                }
            }
        }
    }
}
