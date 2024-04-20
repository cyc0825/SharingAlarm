//
//  AlarmsViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import Foundation
import CloudKit

struct Alarm: Hashable {
    var recordID: CKRecord.ID
    var time: Date
    var sound: String
    var repeatInterval: String
}

class AlarmsViewModel: ObservableObject {
    @Published var alarms: [Alarm] = [] {
        didSet {
            //saveAlarms()
        }
    }
    @Published var selectedAlarm: Alarm?

    let alarmsKey = "alarmsData"

    let sounds = ["Harmony", "Ripples", "Signal"]
    let intervals = ["None", "Daily", "Weekly"]
    
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
                    let alarm = Alarm(recordID: recordID, time: record["time"] as? Date ?? Date(), sound: record["sound"] as? String ?? "Nil", repeatInterval: record["interval"] as? String ?? "Nil")
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
    var nextAlarm: Alarm? {
        alarms.sorted { $0.time < $1.time }.first(where: { $0.time > Date() })
    }
    
    func timeUntilNextAlarm() -> String {
        guard let nextAlarm = nextAlarm else { return "No upcoming alarms" }
        let timeInterval = nextAlarm.time.timeIntervalSinceNow
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        return "\(hours) hours, \(minutes) minutes remaining"
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
