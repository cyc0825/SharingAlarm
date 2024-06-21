//
//  AlarmsViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import Foundation
import CloudKit
import AudioToolbox
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

struct Alarm: Hashable, Codable, Identifiable {
    @DocumentID var id: String?
    var time: Date
    var sound: String
    var repeatInterval: String
    
    var notificationIdentifier: String?
    
    var remainingTime: TimeInterval {
        max(0, time.timeIntervalSince(Date()))
    }
    
}

@MainActor
class AlarmsViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var selectedAlarm: Alarm?
    var timer: Timer?

    let alarmsKey = "alarmsData"

    let sounds = ["Harmony", "Ripples", "Signal"]
    let intervals = ["None", "Daily", "Weekly"]
    
    // For notification extension
    var vibrationTimer: Timer?
    var rescheduleTimer: Timer?
    
    private var db = Firestore.firestore()
    
    init() {
        fetchAlarmData()
    }
    
    func startGlobalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.objectWillChange.send() // Notify SwiftUI to update the views
            self.checkAlarms()
        }
    }
    
    func checkAlarms() {
        for alarm in alarms {
            if alarm.remainingTime <= 0 {
                removeAlarm(documentID: alarm.id)
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func fetchAlarmData() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                let querySnapshot = try await db.collection("UserData").document(userID)
                    .collection("Alarms")
                    .getDocuments()
                if !querySnapshot.isEmpty {
                    for document in querySnapshot.documents {
                        Task {
                            do {
                                let alarm = try document.data(as: Alarm.self)
                                if !self.alarms.contains(where: { $0.id == alarm.id }) {
                                    self.alarms.append(alarm)
                                }
                            }
                            catch {
                                print(error.localizedDescription)
                            }
                        }
                    }
                } else {
                    self.alarms = []
                }
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func saveAlarm(time: Date, sound: String, repeatInterval: String) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                try await db.collection("UserData").document(userID)
                    .collection("Alarms")
                    .addDocument(data: ["time": time,
                                        "sound": sound,
                                        "repeatInterval": repeatInterval
                                       ])
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func removeAlarm(documentID: String?) {
        guard let documentID = documentID else { return }
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                debugPrint("[removeAlarm] starts")
                try await db.collection("UserData").document(userID)
                    .collection("Alarms")
                    .document(documentID).delete()
            } catch {
                debugPrint("Error removing alarm: \(error.localizedDescription)")
            }
            self.alarms.remove(at: 0)
            print("Alarm has finished its Mission")
            debugPrint("[removeAlarm] ends")
        }
        
    }
}

extension AlarmsViewModel {

    func startLongVibration() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        vibrationTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(vibrate), userInfo: nil, repeats: true)
        rescheduleTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(stopVibrationAndReschedule), userInfo: nil, repeats: false)
    }

    @objc private func stopVibrationAndReschedule() {
        stopVibration()
        // rescheduleAlarm()
    }
    
    @objc private func vibrate() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    func stopVibration() {
        DispatchQueue.main.async {
            if let vibrationTimer = self.vibrationTimer {
                vibrationTimer.invalidate()
            } else {
                print("vibrationTimer not exist")
            }
            self.vibrationTimer = nil
        }
    }
}

class AlarmDetailsViewModel: ObservableObject {
    var alarm: Alarm? {
        didSet {
            if let alarm = alarm {
                time = alarm.time
                repeatInterval = alarm.repeatInterval
                sound = alarm.sound
            }
        }
    }
    
    @Published var time: Date = Date()
    @Published var repeatInterval: String = ""
    @Published var sound: String = "Default"
    
    // Add functionality to modify alarm details as needed
}
