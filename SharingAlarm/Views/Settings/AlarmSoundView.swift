//
//  AlarmSoundView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/7.
//

import SwiftUI
import AVFoundation

struct AlarmSoundView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject var viewModel: AlarmsViewModel
    
    @StateObject var arViewModel: AudioRecorderViewModel
    @State var showRecordingView = false
    @State private var audioPlayer: AVAudioPlayer?
    // @State private var downloadURL: URL?
    
    // Function to play the sound
    private func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "caf") else {
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
                Section("Premium Ringtone") {
                    NavigationLink(destination: RingtoneLib(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "storefront")
                            Text("Ringtone Shop")
                        }
                        .foregroundStyle(.accent)
                    }
                }
                
                Section("Personalized Ringtone") {
                    AudioRecorderView(alarmsViewModel: viewModel)
                }
                
                Section("Unlocked Ringtone") {
                    List(viewModel.ringtones, id: \.self) { ringtone in
                        Button(action: {
                            playSound(named: ringtone.name)
                        }) {
                            Text(ringtone.name)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationTitle("Ringtone Library")
        .navigationBarTitleDisplayMode(.automatic)
    }
}

#Preview {
    AlarmSoundView(viewModel: AlarmsViewModel(), arViewModel: AudioRecorderViewModel(), showRecordingView: false)
}
