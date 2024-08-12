//
//  TimerView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/7.
//

import SwiftUI

struct CountDownTimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        VStack {
            Text(timeString(time: viewModel.timeRemaining))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .tint(.accent)
                .onAppear {
                    viewModel.startTimer(targetDate: Date().addingTimeInterval(viewModel.timeRemaining))
                }
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        guard time < 86400 else {
            return "> One Day"
        }
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = (Int(time) % 3600) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
