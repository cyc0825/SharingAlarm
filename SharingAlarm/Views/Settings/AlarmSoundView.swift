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
    
    @StateObject var arViewModel: AudioRecorderViewModel
    @State var showRecordingView = false
    @State private var audioPlayer: AVAudioPlayer?
    @State var presentPremiumStoreView = false
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
                                .foregroundStyle(.accent)
                            Text("Ringtone Shop")
                        }
                    }
                }
                
                Section("Personalized Ringtone") {
                    ZStack {
                        AudioRecorderView(alarmsViewModel: viewModel)
                        if UserDefaults.standard.bool(forKey: "isPremium")  {
                            Color.clear
                                .background(.ultraThinMaterial)
                                .onTapGesture {
                                    // Present PremiumStoreView when tapped
                                    presentPremiumStoreView = true
                                }
                                .padding(.horizontal, -20)
                                .padding(.vertical, -5)
                            VStack {
                                Image(systemName: "lock.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Unlock Personalized Ringtone")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
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
        .sheet(isPresented: $presentPremiumStoreView) {
            PremiumStoreView()
        }
        .navigationTitle("Ringtone Library")
        .navigationBarTitleDisplayMode(.automatic)
    }
}

#Preview {
    AlarmSoundView(viewModel: AlarmsViewModel(), arViewModel: AudioRecorderViewModel(), showRecordingView: false)

}
