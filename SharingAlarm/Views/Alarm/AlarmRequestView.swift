//
//  AlarmRequestView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/16.
//

import Foundation
import SwiftUI

struct AlarmRequestView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) var dismiss
    @ObservedObject var alarmViewModel: AlarmsViewModel
    var alarm: Alarm
    var fcmToken = UserDefaults.standard.value(forKey: "fcmToken") as? String
    
    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
                Text("You have an alarm request for")
                    .fontDesign(.serif)
                Text(alarm.time.formatted(date: .long, time: .omitted))
                    .font(.largeTitle)
                    .fontDesign(.serif)
                Text(alarm.time.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 60))
                    .fontDesign(.serif)
                Text("In group: \(alarm.groupName ?? "")")
                    .fontDesign(.serif)
                Spacer()
                Button {
                    print("Add Alarm \(alarm.id ?? "")")
                    if let id = alarm.id {
                        Task {
                            // Fetch alarm count asynchronously
                            // let alarmCount = try await alarmViewModel.fetchAlarmsCount()
                            
                            // Print the subscription status and alarm count
                            print("Subscription \(UserDefaults.standard.bool(forKey: "isPremium"))")
                            print("Alarm Count \(alarmViewModel.alarms.count)")
                            
                            // Check the user's subscription status or alarm count
                            if UserDefaults.standard.bool(forKey: "isPremium")  || alarmViewModel.alarms.count < 3 {
                                // Proceed to add the alarm to the participant and schedule it
                                alarmViewModel.addAlarmToParticipant(alarmId: id, groupId: alarm.groupID ?? "") { result in
                                    switch result {
                                    case .success(_):
                                        // Schedule the alarm after successfully adding the participant
                                        alarmViewModel.scheduleAlarm(
                                            alarmTime: alarm.time.ISO8601Format(),
                                            alarmBody: alarm.alarmBody,
                                            alarmId: id,
                                            ringTone: alarm.sound,
                                            deviceToken: fcmToken ?? ""
                                        )
                                        print("Success")
                                    case .failure(_):
                                        print("fail")
                                    }
                                }
                            } else {
                                // Show an error if the user has reached the maximum number of alarms
                                alarmViewModel.errorMessage = "You have reached the maximum number of alarms basic user can have."
                            }
                        }

                    }
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(.systemText)
                }
                .background(Color.thirdAccent)
                .cornerRadius(25)
                .padding(.horizontal)
                Button {
                    if let id = alarm.id {
                        alarmViewModel.rejectAlarm(alarmId: id) { result in
                            if case .success(_) = result {
                                print("Success")
                            } else {
                                print("fail")
                            }
                        }
                    }
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(.systemText)
                }
                .background(Color.secondAccent)
                .cornerRadius(25)
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .alert(isPresented: .constant(alarmViewModel.errorMessage != nil)) {
                Alert(title: Text("Cannot Add Alarm"),
                      message: Text(alarmViewModel.errorMessage ?? "Unknown Error"),
                      dismissButton:.default(Text("Confirm"), action: {
                    alarmViewModel.errorMessage = nil
                }))
            }
            .padding()
        }
    }
}

