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
    
    @StateObject var arViewModel: AudioRecorderViewModel
    @State var showRecordingView = false
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
                
                Section(header: HStack {
                                Text("Recorded Sound")
                                Spacer()
                                Button(action: {
                                    if arViewModel.isRecording {
                                        arViewModel.stopRecording()
                                        showRecordingView = true
                                    } else {
                                        arViewModel.startRecording()
                                    }
                                }) {
                                    Image(systemName: arViewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                        .font(.title2)
                                }
                            }) {
                                if let recordedAudioURL = arViewModel.recordedAudioURL {
                                    Button(action: {
                                        arViewModel.playRecording()
                                    }) {
                                        HStack {
                                            Text("Play Recorded Sound")
                                            Spacer()
                                            Image(systemName: arViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                .font(.title2)
                                        }
                                    }
                                } else {
                                    Text("No recorded sound available.")
                                }
                            }
            }
            
        }
        .sheet(isPresented: $showRecordingView) {
            VStack {
                Text("Recorded Sound")
                Button(action: {
                    arViewModel.playRecording()
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.largeTitle)
                }
                .padding()
                Button("Save") {
                    showRecordingView = false
                    // Handle saving the recording
                }
            }
            .presentationDetents([.fraction(0.3), .large])
            .presentationDragIndicator(.visible)
        }
        .navigationTitle("Alarm Sound")
        .navigationBarTitleDisplayMode(.automatic)
    }
}

#Preview {
    AlarmSoundView(viewModel: AlarmsViewModel(), userViewModel: UserViewModel(), arViewModel: AudioRecorderViewModel(), showRecordingView: false)
}
