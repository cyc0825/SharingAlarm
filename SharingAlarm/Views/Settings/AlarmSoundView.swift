//
//  AlarmSoundView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/7.
//

import SwiftUI

struct AlarmSoundView: View {
    @ObservedObject var viewModel: AlarmsViewModel
    @StateObject var userViewModel: UserViewModel
    
    @StateObject var arViewModel: AudioRecorderViewModel
    @State var showRecordingView = false
    // @State private var downloadURL: URL?
    
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
                Section("Personalized Sound") {
                    AudioRecorderView(alarmsViewModel: viewModel)
                }
                // MARK: VIP can uncomment this out
//                .disabled(true)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationTitle("Alarm Sound")
        .navigationBarTitleDisplayMode(.automatic)
    }
}

#Preview {
    AlarmSoundView(viewModel: AlarmsViewModel(), userViewModel: UserViewModel(), arViewModel: AudioRecorderViewModel(), showRecordingView: false)
}
