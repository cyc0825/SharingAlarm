//
//  AlarmsViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import Foundation

struct Alarm: Identifiable, Codable {
    var id = UUID()
    var time: Date
    var sound: String
    var repeatInterval: String
}

class AlarmsViewModel: ObservableObject {
    @Published var alarms: [Alarm] = [] {
        didSet {
            saveAlarms()
        }
    }

    let alarmsKey = "alarmsData"

    init() {
        loadAlarms()
    }
    let sounds = ["Harmony", "Ripples", "Signal"]
    let intervals = ["None", "Daily", "Weekly"]
    
    func loadAlarms() {
        guard let data = UserDefaults.standard.data(forKey: alarmsKey),
              let storedAlarms = try? JSONDecoder().decode([Alarm].self, from: data) else { return }
        self.alarms = storedAlarms
    }

    func saveAlarms() {
        if let encodedData = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encodedData, forKey: alarmsKey)
        }
    }
    
    func addAlarm(time: Date) {
        let newAlarm = Alarm(time: time, sound: "Harmony", repeatInterval: "None")
        alarms.append(newAlarm)
    }
    
    func removeAlarm(with id: UUID) {
        if let index = alarms.firstIndex(where: { $0.id == id }) {
            alarms.remove(at: index)
            saveAlarms()
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
