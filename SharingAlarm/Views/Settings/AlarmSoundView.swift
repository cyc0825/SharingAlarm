//
//  AlarmSoundView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/7.
//

import SwiftUI

struct AlarmSoundView: View {
    @StateObject var viewModel: AlarmsViewModel
    @StateObject var userViewModel: UserViewModel
    var body: some View {
        VStack {
            Form {
                Section("Unlocked Alarm Sound") {
                    List(viewModel.sounds, id: \.self) { sound in
                        Text(sound)
                    }
                }
                
                Section("Premium Alarm Sound") {
                    List(viewModel.paidSounds, id: \.self) { sound in
                        Text(sound)
                    }
                }
                
                Section("Personalized Alarm Sound") {
                    Text("Personalized Sound will be available soon")
                }
            }
        }
        .navigationTitle("Alarm Sound")
        .navigationBarTitleDisplayMode(.automatic)
    }
}
