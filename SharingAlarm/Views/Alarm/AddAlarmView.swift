//
//  AddAlarmView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/7/28.
//

import SwiftUI
import ActivityKit

struct AddAlarmView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject var viewModel: AlarmsViewModel
    @ObservedObject var groupsViewModel: GroupsViewModel
    @Binding var isPresented: Bool // To dismiss the view
    @State private var selectedTime = Date()
    @State private var repeatInterval = "None"
    @State private var selectedRingtone = Ringtone(name: "Classic", filename: "Classic.caf", price: 0)
    @State private var alarmBody: String = "wake up"
    @State private var selectedGroup: Groups? = nil
    @State private var showingAddGroup = false
    
    var name = UserDefaults.standard.string(forKey: "name") ?? "SharingAlarm"
    
    var body: some View {
        NavigationView {
            Form {
                Section("Alarm Display Preview") {
                    NotificationBannerCard(alarmBody: $alarmBody, alarmTime: $selectedTime)
                        .padding(.horizontal, -20)
                        .padding(.vertical, -10)
                    HStack {
                        Text("wants you to")
                        TextField("wake up", text: $alarmBody)
                    }
                }
                
                Section {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Repeat", selection: $repeatInterval) {
                        ForEach(viewModel.intervals, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
//                    Picker("Ringtone", selection: $selectedSound) {
//                        ForEach(viewModel.ringtones, id: \.self) { ringtone in
//                            Text(ringtone.name).tag("\(ringtone.name).caf")
//                        }
//                        ForEach(viewModel.personalizedSounds, id: \.self) { sound in
//                            Text(sound).tag("\(sound).caf")
//                        }
//                    }
                    NavigationLink(destination: RingtonePickerView(selectedRingtone: $selectedRingtone, alarmsViewModel: viewModel)) {
                        HStack {
                            Text("Ringtone")
                            Spacer()
                            Text(selectedRingtone.name)
                                .foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink(destination: GroupPickerView(selectedGroup: $selectedGroup, groupsViewModel: groupsViewModel, groups: groupsViewModel.groups)) {
                        HStack {
                            Text("Group")
                            Spacer()
                            Text(selectedGroup?.name ?? "Just For You")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Alarm Setting")
                } footer: {
                    Text("IMPORTANT: Make sure you turn off the silent mode. In order to allow alarms to ring in DO NOT DISTURB mode, please enable it through \"Settings -> Do Not Disturb\" and set SharingAlarm as an exception.")
                }
            }
            .navigationBarTitle("Add Alarm", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                if selectedTime < Date() {
                    // The selected time has already passed
                    viewModel.errorMessage = "The selected time has already passed. Please choose a future time."
                } else if UserDefaults.standard.bool(forKey: "isPremium") || viewModel.alarms.count < 3 {
                    //                viewModel.alarms.append(Alarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval, groupID: selectedGroup?.id, groupName: selectedGroup?.name))
                    viewModel.addAlarm(
                        alarmBody: "\(name) wants you to \(alarmBody)",
                        time: selectedTime,
                        sound: selectedRingtone.filename,
                        repeatInterval: repeatInterval,
                        groupId: selectedGroup?.id,
                        groupName: selectedGroup?.name
                    ) { result in
                        switch result {
                        case .success(_):
                            // modify the front-end, local groups should not be too large, thus using firstIndex
//                            if let selectedGroup = selectedGroup,
//                               let index = groupsViewModel.groups.firstIndex(where: { $0.id == selectedGroup.id }) {
//                                groupsViewModel.groups[index].alarmCount += 1
//                            }
                            userViewModel.updateUserStatic(field: "alarmScheduled", value: 1)
//                            startAlarmLiveActivity(alarmTime: selectedTime, alarmBody: alarmBody)
                        case .failure(let error):
                            debugPrint("Add Group error: \(error)")
                        }
                    }
                    isPresented = false
                } else {
                    print("Alarm Maximum Reached")
                    viewModel.errorMessage = "You have reached the maximum number of alarms basic user can have."
                }
            })
            .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
                Alert(title: Text("Cannot Add Alarm"),
                      message: Text(viewModel.errorMessage ?? "Unknown Error"),
                      dismissButton:.default(Text("Confirm"), action: {
                    viewModel.errorMessage = nil
                }))
            }
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView(viewModel: groupsViewModel)
            }
        }
    }
}

struct AddAlarmView_Previews: PreviewProvider {
    @State static var isPresent = true
    static var previews: some View {
        AddAlarmView(viewModel: AlarmsViewModel(), groupsViewModel: GroupsViewModel(), isPresented: $isPresent)
    }
}
