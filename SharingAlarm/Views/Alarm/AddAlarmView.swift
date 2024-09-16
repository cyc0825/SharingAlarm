//
//  AddAlarmView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/7/28.
//

import SwiftUI
import ActivityKit

struct AddAlarmView: View {
    @ObservedObject var viewModel: AlarmsViewModel
    @ObservedObject var groupsViewModel: GroupsViewModel
    @Binding var isPresented: Bool // To dismiss the view
    @State private var selectedTime = Date()
    @State private var repeatInterval = "None"
    @State private var selectedSound = "Classic.m4a"
    @State private var alarmBody: String = "wake up"
    @State private var selectedGroup: Groups? = nil
    
    var name = UserDefaults.standard.string(forKey: "name") ?? "SharingAlarm"
    
    var body: some View {
        NavigationView {
            Form {
                Section("Alarm Display Info") {
                    NotificationBannerCard(alarmBody: $alarmBody, alarmTime: $selectedTime)
                        .padding(.horizontal, -20)
                        .padding(.vertical, -10)
                    HStack {
                        Text("wants you to")
                        TextField("wake up", text: $alarmBody)
                    }
                }
                
                Section("Alarm Setting") {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Repeat", selection: $repeatInterval) {
                        ForEach(viewModel.intervals, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    Picker("Sound", selection: $selectedSound) {
                        ForEach(viewModel.ringtones, id: \.self) { ringtone in
                            Text(ringtone.name).tag("\(ringtone.name).m4a")
                        }
                        ForEach(viewModel.personalizedSounds, id: \.self) { sound in
                            Text(sound).tag("\(sound).m4a")
                        }
                    }
                    Picker("Group", selection: $selectedGroup) {
                        Text("Just For You").tag(nil as Groups?)
                        
                        ForEach(groupsViewModel.groups, id: \.id) { group in
                            Text(group.name).tag(group as Groups?)
                        }
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
                    //                viewModel.alarms.append(Alarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval, groupID: selectedGroup?.id, groupName: selectedGroup?.name))
                    viewModel.addAlarm(
                        alarmBody: "\(name) wants you to \(alarmBody)",
                        time: selectedTime,
                        sound: selectedSound,
                        repeatInterval: repeatInterval,
                        groupId: selectedGroup?.id,
                        groupName: selectedGroup?.name
                    ) { result in
                        switch result {
                        case .success(_):
                            // modify the front-end, local groups should not be too large, thus using firstIndex
                            if let selectedGroup = selectedGroup,
                               let index = groupsViewModel.groups.firstIndex(where: { $0.id == selectedGroup.id }) {
                                groupsViewModel.groups[index].alarmCount += 1
                            }
                            startAlarmLiveActivity(alarmTime: selectedTime, alarmBody: alarmBody)
                        case .failure(let error):
                            debugPrint("Add Group error: \(error)")
                        }
                    }
                    isPresented = false
                } else {
                    print("Alarm Maximum Reached")
                    viewModel.errorMessage = "You have reached the maximum number of alarms trial user can have."
                }
            })
            .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
                Alert(title: Text("Cannot Add"),
                      message: Text(viewModel.errorMessage ?? "Unknown Error"),
                      dismissButton:.default(Text("Confirm"), action: {
                    viewModel.errorMessage = nil
                }))
            }
        }
    }
    
    func startAlarmLiveActivity(alarmTime: Date, alarmBody: String) {
        let initialContentState = AlarmAttributes.ContentState(remainingTime: alarmTime.timeIntervalSinceNow, alarmBody: alarmBody)
        let attributes = AlarmAttributes(alarmTime: alarmTime, alarmBody: alarmBody)

        do {
            let _ = try Activity<AlarmAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: nil)
            print("Started Live Activity")
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
}

struct AddAlarmView_Previews: PreviewProvider {
    @State static var isPresent = true
    static var previews: some View {
        AddAlarmView(viewModel: AlarmsViewModel(), groupsViewModel: GroupsViewModel(), isPresented: $isPresent)
    }
}
