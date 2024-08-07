//
//  AlarmView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/8.
//

import SwiftUI
import AVFoundation

struct AlarmView: View {
    var title: String
    var alarmBody: String
    var alarmTime: Date
    var sound: String
    var onClose: () -> Void
    var onSnooze: () -> Void

    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea(edges: .all)
            VStack {
                Text(title)
                    .font(.largeTitle)
                    .padding()
                
                Text(alarmBody)
                    .font(.title)
                    .padding()
                
                HStack {
                    Button(action: {
                        // Stop vibration
                        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
                        onClose()
                    }) {
                        Text("Close")
                            .font(.title)
                            .padding()
                            .background(Color.thirdAccent)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Stop vibration
                        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
                        onSnooze()
                    }) {
                        Text("Snooze")
                            .font(.title)
                            .padding()
                            .background(Color.secondary)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Start vibration
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
}
