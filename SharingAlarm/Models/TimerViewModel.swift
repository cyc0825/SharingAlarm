//
//  TimerViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/7.
//

import SwiftUI
import Combine

class TimerViewModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    private var cancellable: AnyCancellable?
    var onTimerEnd: (() -> Void)?
    
    init(targetDate: Date) {
        startTimer(targetDate: targetDate)
    }
    
    func startTimer(targetDate: Date) {
        let now = Date()
        timeRemaining = targetDate.timeIntervalSince(now)
        
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                let now = Date()
                self.timeRemaining = targetDate.timeIntervalSince(now)
                
                if self.timeRemaining <= 0 {
                    self.cancellable?.cancel()
                    self.timeRemaining = 0
                    self.onTimerEnd?()
                }
            }
    }
}
