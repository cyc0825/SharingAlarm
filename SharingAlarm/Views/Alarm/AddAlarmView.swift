//
//  AddAlarmView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/7/28.
//

import SwiftUI

struct AddAlarmView: View {
    @ObservedObject var viewModel: AlarmsViewModel
    @StateObject var activityViewModel = ActivitiesViewModel()
    @Binding var isPresented: Bool // To dismiss the view
    @State private var selectedTime = Date()
    @State private var repeatInterval = "None"
    @State private var selectedSound = "Harmony"
    @State private var selectedGroup = "None"
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                
                Picker("Repeat", selection: $repeatInterval) {
                    ForEach(repeatOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                Picker("Sound", selection: $selectedSound) {
                    ForEach(sounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                Picker("Group", selection: $selectedGroup) {
                    ForEach(activityViewModel.activities, id: \.self) { activity in
                        Text(activity.name).tag(activity.id)
                    }
                }
            }
            .onDisappear {
                viewModel.fetchAlarmData()
            }
            .navigationBarTitle("Add Alarm", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                viewModel.addAlarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval, activityId: selectedGroup) { result in
                    switch result {
                    case .success(let alarm):
                        viewModel.alarms.append(alarm)
                    case .failure(let error):
                        debugPrint("Add Activity error: \(error)")
                    }
                }
                let newAlarm = Alarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval)
                scheduleNotification(for: newAlarm, viewModel: viewModel)
                isPresented = false
            })
        }
    }
}
