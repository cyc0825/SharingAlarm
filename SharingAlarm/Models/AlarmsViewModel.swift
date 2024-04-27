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

struct Alarm: Hashable {
    var recordID: CKRecord.ID
    var time: Date
    var sound: String
    var repeatInterval: String
    
    var notificationIdentifier: String?
    
    var remainingTime: TimeInterval {
        max(0, time.timeIntervalSince(Date()))
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AlarmData", recordID: recordID)
        record["time"] = time
        record["sound"] = sound
        record["interval"] = repeatInterval
        record["notificationIdentifier"] = notificationIdentifier
        return record
    }
    
}

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
    
    func startGlobalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.objectWillChange.send() // Notify SwiftUI to update the views
            self.checkAlarms()
        }
    }
    
    func checkAlarms() {
        for index in alarms.indices {
            if alarms[index].remainingTime <= 0 {
                removeAlarm(recordID: alarms[index].recordID) { result in
                    switch result {
                    case .success():
                        self.alarms.remove(at: index)
                        print("Alarm has finished its Mission")
                    case .failure(let error):
                        print("Alarm cannot finished its Mission because \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func fetchUpdatedRecords() {
        let lastFetchDate = UserDefaults.standard.value(forKey: "lastAlarmFetchDate") as? Date ?? Date.distantPast
        let predicate = NSPredicate(format: "modificationDate > %@", lastFetchDate as CVarArg)
        let query = CKQuery(recordType: "AlarmData", predicate: predicate)
        
        // You can also specify sorting if needed
        let sortDescriptor = NSSortDescriptor(key: "modificationDate", ascending: true)
        query.sortDescriptors = [sortDescriptor]
        let operation = CKQueryOperation(query: query)
        var mostRecentUpdate: Date = lastFetchDate
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                DispatchQueue.main.async {
                    guard !self.alarms.contains(where: { $0.recordID == recordID }) else {
                        return
                    }
                    if let modificationDate = record.modificationDate, modificationDate > mostRecentUpdate {
                        mostRecentUpdate = modificationDate
                    }
                    let alarm = Alarm(
                        recordID: recordID,
                        time: record["time"] as? Date ?? Date(),
                        sound: record["sound"] as? String ?? "Nil",
                        repeatInterval: record["interval"] as? String ?? "Nil",
                        notificationIdentifier: record["notificationIdentifier"]
                    )
                    self.alarms.append(alarm)
                    self.alarms.sort {
                        $0.time < $1.time
                    }
                }
            case .failure(let error):
                print("Error fetching record: \(error)")
            }
        }
        operation.queryResultBlock = { result in
            switch result {
            case .success(let cursor):
                if let cursor = cursor {
                    print("Additional data available with cursor: \(cursor)")
                } else {
                    print("Fetched all data. No additional data to fetch.")
                }
            case .failure(let error):
                print("Query failed with error: \(error.localizedDescription)")
            }
        }
        UserDefaults.standard.set(mostRecentUpdate, forKey: "lastAlarmFetchDate")
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func addAlarm(time: Date, sound: String, repeatInterval: String, completion: @escaping (Result<Alarm, Error>) -> Void) {
        let newAlarm = CKRecord(recordType: "AlarmData")
        newAlarm["time"] = time
        newAlarm["sound"] = sound
        newAlarm["interval"] = repeatInterval
        
        CKContainer.default().publicCloudDatabase.save(newAlarm) { (record, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else if let recordID = record?.recordID {
                    let newAlarm = Alarm(recordID: recordID, time: time, sound: sound, repeatInterval: repeatInterval)
                    self.alarms.append(newAlarm)
                    completion(.success((newAlarm)))
                }
            }
        }
    }
    
    func removeAlarm(recordID: CKRecord.ID, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Removing")
        CKContainer.default().publicCloudDatabase.delete(withRecordID: recordID) { (record, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
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
