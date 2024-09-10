//
//  AlarmSoundView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/7.
//

import SwiftUI
import AVFoundation

struct AlarmSoundView: View {
    @ObservedObject var viewModel: AlarmsViewModel
    @StateObject var userViewModel: UserViewModel
    
    @StateObject var arViewModel: AudioRecorderViewModel
    @State var showRecordingView = false
    @State private var audioPlayer: AVAudioPlayer?
    // @State private var downloadURL: URL?
    
    // Function to play the sound
    private func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "m4a") else {
            print("Sound file not found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        VStack {
            Form {
                Section("Unlocked Ringtone") {
                    List(viewModel.sounds.prefix(2), id: \.self) { sound in
                        Button(action: {
                            playSound(named: sound)
                        }) {
                            Text(sound)
                        }
                    }
                    NavigationLink(destination: RingtoneLib(ringToneType: "Free")) {
                        Text("See More")
                    }
                }
                
                Section("Premium Ringtone") {
                    List(viewModel.paidSounds.prefix(2), id: \.self) { sound in
                        Button(action: {
                            playSound(named: sound)
                        }) {
                            Text(sound)
                        }
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
