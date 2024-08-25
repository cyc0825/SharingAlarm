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
    @State private var selectedSound = "Classic.m4a"
    @State private var selectedGroup: Activity? = nil
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Time", selection: $selectedTime, displayedComponents: [.date, .hourAndMinute])
                
                Picker("Repeat", selection: $repeatInterval) {
                    ForEach(viewModel.intervals, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                Picker("Sound", selection: $selectedSound) {
                    ForEach(viewModel.sounds + viewModel.paidSounds + viewModel.personalizedSounds, id: \.self) { sound in
                        Text(sound).tag("\(sound).m4a")
                    }
                }
                Picker("Group", selection: $selectedGroup) {
                    Text("Just For You").tag(nil as Activity?)
                    
                    ForEach(activityViewModel.activities, id: \.id) { activity in
                        Text(activity.name).tag(activity as Activity?)
                    }
                }
            }
            .navigationBarTitle("Add Alarm", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                if selectedTime < Date() {
                    // The selected time has already passed
                    viewModel.errorMessage = "The selected time has already passed. Please choose a future time."
                } else if viewModel.alarms.count < 10 {
                    //                viewModel.alarms.append(Alarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval, activityID: selectedGroup?.id, activityName: selectedGroup?.name))
                    viewModel.addAlarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval, activityId: selectedGroup?.id, activityName: selectedGroup?.name) { result in
                        switch result {
                        case .success(_):
                            // modify the front-end, local activities should not be too large, thus using firstIndex
                            if let selectedGroup = selectedGroup,
                               let index = activityViewModel.activities.firstIndex(where: { $0.id == selectedGroup.id }) {
                                activityViewModel.activities[index].alarmCount += 1
                            }
                        case .failure(let error):
                            debugPrint("Add Activity error: \(error)")
                        }
                    }
                    isPresented = false
                } else {
                    print("Alarm Maximum Reached")
                    viewModel.errorMessage = "You have reached the maximum number of alarms trial user can have."
                }
            })
            .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
                Alert(title: Text("Cannot Add Alarm"), message: Text(viewModel.errorMessage ?? "Unknown Error"), dismissButton: .default(Text("Confirm")))
            }
        }
    }
}
