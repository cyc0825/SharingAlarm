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
                Section("Unlocked Ringtone") {
                    List(viewModel.sounds.prefix(2), id: \.self) { sound in
                        Text(sound)
                    }
                    NavigationLink(destination: RingtoneLib(ringToneType: "Free")) {
                        Text("See More")
                    }
                }
                
                Section("Premium Ringtone") {
                    List(viewModel.paidSounds.prefix(2), id: \.self) { sound in
                        Text(sound)
                    }
                    NavigationLink(destination: RingtoneLib(ringToneType: "Premium")) {
                        Text("See More")
                    }
                }
                Section("Personalized Ringtone") {
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
