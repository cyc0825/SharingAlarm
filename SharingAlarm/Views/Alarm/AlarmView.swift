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
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject var alarmViewModel: AlarmsViewModel
    var userID = UserDefaults.standard.string(forKey: "userID") ?? nil
    var body: some View {
        ZStack {
            Color.secondAccent.ignoresSafeArea(edges: .all)
            if let alarm = alarmViewModel.selectedAlarm {
                AlarmStatusView(alarm: alarm, alarmViewModel: alarmViewModel)
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
                        AlarmStatusView(alarm: alarm, alarmViewModel: alarmViewModel)
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

struct AlarmStatusView: View {
    var alarm: Alarm
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject var alarmViewModel: AlarmsViewModel
    @StateObject var economy = EconomyViewModel()
    @State private var isLocked = true
    @State private var showCoinPopup = false
    @State private var earnedCoins: Int = 0
    var userID = UserDefaults.standard.string(forKey: "userID") ?? nil
    
    var body: some View {
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
            CoinEarnedPopupCard(isVisible: $showCoinPopup, coinsEarned: earnedCoins)
            if alarm.time < Date() {
                if !alarmViewModel.ifUserStopped(participants: alarm.participants) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            BackgroundComponent()
                            DraggingComponent(isLocked: $isLocked, onClose: {
                                // Stop vibration
                                AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
                                alarmViewModel.stopVibration()
                                let responseTime = Int(alarm.time.timeIntervalSince(Date())) * -1
                                print("alarm.alarmTime: \(alarm.alarmTime)")
                                print("responseTime: \(responseTime)")
                                Task {
                                    if alarm.alarmTime > 7200 && responseTime < 30 {
                                        earnedCoins = 30 - responseTime
                                        try await economy.updateCoinsForResponse(alarm: alarm, earnedCoins: earnedCoins, userID: userID)
                                        userViewModel.appUser.money += earnedCoins
                                        showCoinPopup = true
                                    }
                                    if alarm.participants.count == 1 {
                                        // Only one participant, no need to wait for others
                                        alarmViewModel.removeAlarm(documentID: alarm.id)
                                        dismiss()
                                    } else {
                                        alarmViewModel.setUserStatus(alarmId: alarm.id, status: "Stopped", participants: alarm.participants)
                                    }
                                }
                            }, maxWidth: geometry.size.width)
                        }
                    }
                    .frame(height: 70)
                    .padding(.horizontal, 30)
                    Button(action: {
                        // Stop vibration
                        alarmViewModel.setUserStatus(alarmId: alarm.id, status: "Snoozed", participants: alarm.participants)
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
}
//
//struct AlarmView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleAlarms = [
//            Alarm(time: Date(), sound: "Hi", alarmBody: "cyc wants you to wake up", repeatInterval: "", groupID: "", groupName: "Lunch Time", participants: ["fdjhgdshoidjoijewoasdlk": ["Xiaoming", "Accept"]]),
//            Alarm(time: Date(), sound: "Hello", alarmBody: "cyc wants you to wake up", repeatInterval: "", groupID: "", groupName: "Dinner Time", participants: ["fdjhgdshoidjoijewoasdlk": ["Xiaoming", "Accept"]])
//        ]
//        let viewModel = AlarmsViewModel()
//        viewModel.ongoingAlarms = sampleAlarms
//
//        return AlarmView(alarmViewModel: viewModel)
//    }
//}
