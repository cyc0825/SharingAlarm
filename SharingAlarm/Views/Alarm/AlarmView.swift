//
//  AlarmView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/8.
//

import SwiftUI
import AVFoundation

struct AlarmView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var alarmViewModel: AlarmsViewModel
    @State private var isLocked = true

    var body: some View {
        ZStack {
            Color.secondAccent.ignoresSafeArea(edges: .all)
            if let alarm = alarmViewModel.selectedAlarm {
                VStack {
                    Spacer()
//                    HStack {
//                        Text(alarm.activityName ?? "Just For You")
//                            .font(.largeTitle.bold())
//                            .padding([.leading, .top], 40)
//                            .fontDesign(.serif)
//                        Spacer()
//                    }
                    
                    Text("Time to \(alarm.alarmBody.split(separator: "wants you to")[1])")
                        .font(.title)
                        .fontDesign(.serif)
                        .padding(.horizontal)
                        .padding(.top, 60)
                        .lineLimit(1) // Ensures the text stays on one line
                        .minimumScaleFactor(0.5)
                    Text(alarm.time, style: .time)
                        .font(.system(size: 60))
                        .fontDesign(.serif)
                        .padding(.horizontal)
                    
                    Text(alarm.time, style: .date)
                        .font(.title2)
                        .fontDesign(.serif)
                        .padding(.horizontal)
                        .frame(alignment: .trailing)
                    
                    // Additional alarm information can go here
                    List {
                        Section("Status") {
                            ForEach(Array(alarm.participants), id: \.key) { participantID, participantStatus in
                                HStack {
                                    Text(participantStatus[0])
                                    Spacer()
                                    Text(participantStatus[1])
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    if alarm.time < Date() {
                        if !alarmViewModel.ifUserStopped(participants: alarm.participants) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    BackgroundComponent()
                                    DraggingComponent(isLocked: $isLocked, onClose: {
                                        // Stop vibration
                                        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
                                        alarmViewModel.stopVibration()
                                        if alarm.participants.count == 1 {
                                            // Only one participant, no need to wait for others
                                            alarmViewModel.removeAlarm(documentID: alarm.id)
                                            dismiss()
                                        } else {
                                            alarmViewModel.setUserStop(alarmId: alarm.id, participants: alarm.participants)
                                        }
                                    }, maxWidth: geometry.size.width)
                                }
                            }
                            .frame(height: 70)
                            .padding(.horizontal, 30)
                            Button(action: {
                                // Stop vibration
                                AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
                                alarmViewModel.stopVibration()
                            }) {
                                Text("Snooze")
                            }
                            .padding(.bottom, 60)
                        } else if alarmViewModel.ifAllUserStop(alarmId: alarm.id, participants: alarm.participants) {
                            Button {
                                alarmViewModel.removeAlarm(documentID: alarm.id)
                                dismiss()
                            } label: {
                                Text("Remove Alarm")
                                    .font(.title)
                                    .padding()
                                    .background(Color.primary)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .onAppear {
                    alarmViewModel.startListeningAlarm(forDocument: alarm.id!)
                }
                .onDisappear {
                    alarmViewModel.stopListening()
                }
            }
            else if alarmViewModel.ongoingAlarms.isEmpty {
                // Show a message if there are no active alarms
                Text("There are no active alarms")
                    .font(.title)
                    .padding()
            } else {
                // Create a TabView for ongoing alarms
                TabView {
                    ForEach(alarmViewModel.ongoingAlarms, id: \.self) { alarm in
                        VStack {
                            Spacer()
                            Text("Time to \(alarm.alarmBody.split(separator: "wants you to")[1])")
                                .font(.title)
                                .fontDesign(.serif)
                                .padding(.horizontal)
                                .padding(.top, 60)
                                .lineLimit(1) // Ensures the text stays on one line
                                .minimumScaleFactor(0.5)
                            Text(alarm.time, style: .time)
                                .font(.system(size: 60))
                                .fontDesign(.serif)
                                .padding(.horizontal)
                            
                            Text(alarm.time, style: .date)
                                .font(.title2)
                                .fontDesign(.serif)
                                .padding(.horizontal)
                                .frame(alignment: .trailing)
                            
                            // Additional alarm information can go here
                            List {
                                Section("Status") {
                                    ForEach(Array(alarm.participants), id: \.key) { participantID, participantStatus in
                                        HStack {
                                            Text(participantStatus[0])
                                            Spacer()
                                            Text(participantStatus[1])
                                        }
                                    }
                                    .listRowBackground(Color.clear)
                                }
                            }
                            .listStyle(.plain)
                            if !alarmViewModel.ifUserStopped(participants: alarm.participants) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        BackgroundComponent()
                                        DraggingComponent(isLocked: $isLocked, onClose: {
                                            // Stop vibration
                                            AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
                                            alarmViewModel.stopVibration()
                                            if alarm.participants.count == 1 {
                                                // Only one participant, no need to wait for others
                                                alarmViewModel.removeAlarm(documentID: alarm.id)
                                                dismiss()
                                            } else {
                                                alarmViewModel.setUserStop(alarmId: alarm.id, participants: alarm.participants)
                                            }
                                        }, maxWidth: geometry.size.width)
                                    }
                                }
                                .frame(height: 70)
                                .padding(.horizontal, 30)
                                Button(action: {
                                    // Stop vibration
                                    AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
                                    alarmViewModel.stopVibration()
                                }) {
                                    Text("Snooze")
                                }
                                .padding(.bottom, 60)
                            } else if alarmViewModel.ifAllUserStop(alarmId: alarm.id, participants: alarm.participants) {
                                Button {
                                    alarmViewModel.removeAlarm(documentID: alarm.id)
                                    dismiss()
                                } label: {
                                    Text("Remove Alarm")
                                        .font(.title)
                                        .padding()
                                        .background(Color.primary)
                                        .cornerRadius(10)
                                }
                                
                            }
                        }
                        .onAppear {
                            alarmViewModel.startListeningAlarm(forDocument: alarm.id!)
                        }
                        .onDisappear {
                            alarmViewModel.stopListening()
                        }
                        .tabItem {
                            Text(alarm.sound)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
            }
        }
    }
}
//
//struct AlarmView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleAlarms = [
//            Alarm(time: Date(), sound: "Hi", alarmBody: "cyc wants you to wake up", repeatInterval: "", activityID: "", activityName: "Lunch Time", participants: ["fdjhgdshoidjoijewoasdlk": ["Xiaoming", "Accept"]]),
//            Alarm(time: Date(), sound: "Hello", alarmBody: "cyc wants you to wake up", repeatInterval: "", activityID: "", activityName: "Dinner Time", participants: ["fdjhgdshoidjoijewoasdlk": ["Xiaoming", "Accept"]])
//        ]
//        let viewModel = AlarmsViewModel()
//        viewModel.ongoingAlarms = sampleAlarms
//
//        return AlarmView(alarmViewModel: viewModel)
//    }
//}
