//
//  AudioRecorderView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/3.
//

import SwiftUI

struct AudioRecorderView: View {
    @StateObject private var recorder = AudioRecorderViewModel()
    @StateObject var alarmsViewModel: AlarmsViewModel
    @State private var isRecording = false // State to handle button appearance
    @State private var uploaded = false
    
    var body: some View {
        VStack {
            VStack {
                ZStack {
                    // Display the audiogram next to the play button
                    AudiogramView(recorder: recorder, data: recorder.audiogramData)
                        .frame(height: 100)
                    if recorder.recordedAudioURL != nil && !recorder.isRecording  {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 2)
                    }
                }
                // Conditionally display the play button only if there is a recorded audio URL
                HStack(alignment: .center, spacing: 30) {
                    if recorder.recordedAudioURL != nil && !recorder.isRecording{
                        Button(action: {
                            recorder.discardNewRecording()
                        }) {
                            Image(systemName: "arrowshape.turn.up.backward")
                                .resizable()
                                .frame(width: 20, height: 18)
                        }
                        Button(action: {
                            if recorder.isPlaying {
                                recorder.stopPlaying()
                            } else {
                                recorder.playRecording()
                            }
                        }) {
                            if #available(iOS 17.0, *) {
                                Image(systemName: recorder.isPlaying ? "pause" : "play.fill")
                                    .resizable()
                                    .frame(width: 25, height: 30)
                                    .foregroundColor(.accentColor)
                                    .contentTransition(.symbolEffect(.replace))
                            } else {
                                // Fallback on earlier versions
                                Image(systemName: recorder.isPlaying ? "pause" : "play.fill")
                                    .resizable()
                                    .frame(width: 25, height: 30)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        Button(action: {
                            Task {
                                let success = try await recorder.uploadRecording()
                                if success {
                                    uploaded = true
                                    alarmsViewModel.personalizedSounds.append("YourRecording")
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                                uploaded = false
                            })
                        }) {
                            if #available(iOS 17.0, *) {
                                Image(systemName: uploaded ? "checkmark" : "square.and.arrow.up")
                                    .resizable()
                                    .frame(width: 14, height: 20)
                                    .contentTransition(.symbolEffect(.replace))
                            } else {
                                // Fallback on earlier versions
                                Image(systemName: uploaded ? "checkmark" : "square.and.arrow.up")
                                    .resizable()
                                    .frame(width: 14, height: 20)
                            }
                        }
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .frame(height: 200)
            Spacer()

            // Recording button with animation
            Button(action: {
                withAnimation {
                    if isRecording {
                        recorder.stopRecording()
                        isRecording = false
                    } else {
                        recorder.startRecording()
                        isRecording = true
                    }
                }
            }) {
                ZStack {
                    if isRecording {
                        // Rectangle shape when recording
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .animation(.easeInOut, value: isRecording)
                    } else {
                        // Circle shape when idle
                        Circle()
                            .fill(Color.red)
                            .frame(width: 50, height: 50)
                            .animation(.easeInOut, value: isRecording)
                    }
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(.systemText, lineWidth: 4)
                                .padding(-5)
                        )
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle()) // Ensures no additional button styling affects it
            .disabled(recorder.isPlaying)
        }
        .onAppear {
            recorder.loadLocalRecording() { _ in
            }
        }
        
    }
}


struct AudiogramView: View {
    @StateObject var recorder: AudioRecorderViewModel
    var data: [Float]

    var body: some View {
        let indicatorIndex = Int(CGFloat(data.count) / 2)
        GeometryReader { geometry in
            let width = geometry.size.width / CGFloat(data.count)
            HStack(alignment: .center, spacing: 1) {
                ForEach(data.indices, id: \.self) { index in
                    Capsule()
                        .fill(index < indicatorIndex && !recorder.isRecording ? Color.gray : Color.accentColor)
                        .frame(width: width, height: CGFloat(data[index]) * 100)
                }
            }
            .offset(x: -(width * 3.5))
            .frame(height: 100)
        }
    }
}

#Preview {
    AudioRecorderView(alarmsViewModel: AlarmsViewModel())
}
