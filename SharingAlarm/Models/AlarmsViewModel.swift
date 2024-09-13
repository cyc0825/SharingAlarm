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
    var alarmTime: Double
    var sound: String
    var ringtoneURL: String?
    var alarmBody: String
    var repeatInterval: String
    var groupID: String?
    var groupName: String?
    var participants: [String: [String]] = [:]// Accept, Reject, Stop, Snooze ID: [Name, Status]
    var creatorID: String?
    var creatorName: String?
    var isOn: Bool? = true
    
    var notificationIdentifier: String?
    
    var remainingTime: TimeInterval {
        max(0, time.timeIntervalSince(Date()))
    }
    init(id: String? = nil, time: Date, sound: String, alarmBody: String, repeatInterval: String, groupID: String? = nil, groupName: String? = nil, participants: [String: [String]] = [:], creatorID: String? = nil, creatorName: String? = nil, ringtoneURL: String? = nil) {
            self.id = id
            self.time = time
            self.alarmTime = max(0, time.timeIntervalSince(Date())) // Time interval between now and the alarm time
            self.sound = sound
            self.alarmBody = alarmBody
            self.repeatInterval = repeatInterval
            self.groupID = groupID
            self.groupName = groupName
            self.participants = participants
            self.creatorID = creatorID
            self.creatorName = creatorName
            self.ringtoneURL = ringtoneURL
        }
}

@MainActor
class AlarmsViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var ongoingAlarms: [Alarm] = []
    public var timerViewModels: [String: TimerViewModel] = [:]
    
    @Published var groupNames: Set<String> = []
    @Published var selectedAlarm: Alarm?
    @Published var errorMessage: String? = nil
    
    @Published var ongoingDeletions: Set<String> = []
    var timer: Timer?

    let alarmsKey = "alarmsData"
    
    @Published var showAlarmView: Bool = false

    @Published var ringtones: [Ringtone] = []
    @Published var premiumRingtones: [Ringtone] = []
    @Published var personalizedSounds: [String] = []
    let intervals = ["None", "Daily", "Weekly"]
    
    var groupGroupId: String?
    
    // For notification extension
    var vibrationTimer: Timer?
    var rescheduleTimer: Timer?
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var alarmsListener: ListenerRegistration?
    
    init() {
        // fetchAlarmsData()
    }

    func sortAlarmsByTime() {
        alarms.sort { $0.time < $1.time }
    }
    
//    func filterAlarmsByGroup(groupName: String?) {
//        if !backupAlarms.isEmpty {
//            restoreAlarms()
//        }
//        if let groupName = groupName {
//            print("filter to only show \(groupName)")
//            let filteredAlarm = alarms.filter({
//                $0.groupName == groupName
//            })
//            backupAlarms = alarms
//            alarms = filteredAlarm
//        }
//    }
//    
//    func restoreAlarms() {
//        alarms = backupAlarms
//    }
    
    deinit {
        timer?.invalidate()
        listener?.remove()
        listener = nil
        alarmsListener?.remove()
        alarmsListener = nil
    }
    
    // MARK: Legacy, use listener instead
    func fetchAlarmsData() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            debugPrint("[fetchAlarmsData] starts")
            do {
                let querySnapshot = try await db.collection("UserData").document(userID)
                    .collection("alarms")
                    .getDocuments()
                if !querySnapshot.isEmpty {
                    for document in querySnapshot.documents {
                        Task {
                            do {
                                if document.get("participants") != nil {
                                    // Just For You
                                    print("\(document.documentID) is just for you")
                                    let alarm = try document.data(as: Alarm.self)
                                    if !self.alarms.contains(where: { $0.id == alarm.id }) {
                                        self.alarms.append(alarm)
                                        groupNames.insert(alarm.groupName ?? "")
                                    }
                                } else {
                                    print("\(document.documentID) is for group")
                                    let alarmQuerySnapshot = try await db.collection("Alarm").document(document.documentID).getDocument()
                                    var alarm = try alarmQuerySnapshot.data(as: Alarm.self)
                                    if let isOn = document.get("isOn") as? Bool {
                                        alarm.isOn = isOn
                                    }
                                    if !self.alarms.contains(where: { $0.id == alarm.id }) {
                                        self.alarms.append(alarm)
                                        groupNames.insert(alarm.groupName ?? "")
                                    }
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
                debugPrint("[fetchAlarmsData] error")
                print(error.localizedDescription)
            }
        }
    }
    
    func addAlarm(alarmBody: String, time: Date, sound: String, repeatInterval: String, groupId: String?, groupName: String?, completion: @escaping (Result<Alarm, Error>) -> Void) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        guard let userName = UserDefaults.standard.value(forKey: "name") as? String else { return }
        guard let fcmToken = UserDefaults.standard.value(forKey: "fcmToken") as? String else { return }
        if let groupId = groupId {
            // For sharing alarm
            Task {
                debugPrint("[addAlarm] starts")
                do {
                    var participants: [String: [String]] = [:]
                    let groupRef = db.collection("Groups")
                        .document(groupId)
                    
                    // Count + 1 for group
                    DispatchQueue.main.async {
                        groupRef.updateData([
                            "alarmCount": FieldValue.increment(Int64(1))
                        ]) { error in
                            if let error = error {
                                completion(.failure(error))
                            }
                        }
                    }
                        
                    let participantsDoc = try await groupRef
                        .collection("participants")
                        .getDocuments()
                    
                    for document in participantsDoc.documents {
                        if let userRef = document.get("userRef") as? DocumentReference {
                            
                            let participant = try await userRef.getDocument(as: AppUser.self)
                            participants[participant.id!] = participant.id == userID ? [participant.name, "Accept"] : [participant.name, "Pending"]
                        }
                    }
                    var data = ["alarmBody": alarmBody,
                               "time": time,
                               "alarmTime": max(0, time.timeIntervalSince(Date())),
                               "sound": sound,
                               "repeatInterval": repeatInterval,
                               "groupId": groupId,
                               "groupName": groupName ?? "",
                               "participants": participants,
                               "creatorID": userID,
                               "creatorName": userName
                              ]
                    if sound == "YourRecording.m4a" {
                        guard let ringtoneURL = UserDefaults.standard.url(forKey: "ringtoneURL") else { return }
                        data["ringtoneURL"] = ringtoneURL.absoluteString
                    }
                    print("data now is \(data)")
                    let newAlarm = try await db.collection("Alarm")
                        .addDocument(data: data)
                    let alarm = Alarm(id: newAlarm.documentID, time: time, sound: sound, alarmBody: alarmBody, repeatInterval: repeatInterval, groupID: groupId, groupName: groupName, participants: participants)
                    
                    scheduleAlarm(alarmTime: alarm.time.ISO8601Format(), alarmBody: alarmBody, alarmId: newAlarm.documentID, ringTone: sound, deviceToken: fcmToken)
                    addAlarmToParticipant(alarmId: newAlarm.documentID, groupId: groupId) { result in
                        switch result {
                        case .success(_):
                            DispatchQueue.main.async {
                                completion(.success(alarm))
                            }
                        case .failure(let error):
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        completion(.success(alarm))
                    }
                }
                catch {
                    debugPrint("[addAlarm] error \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
        else {
            // For creating alarm only for self
            Task {
                do {
                    let newAlarm = try await db.collection("UserData").document(userID)
                        .collection("alarms")
                        .addDocument(data: ["alarmBody": alarmBody,
                                            "time": time,
                                            "alarmTime": max(0, time.timeIntervalSince(Date())),
                                            "sound": sound,
                                            "repeatInterval": repeatInterval,
                                            "isOn": true,
                                            "participants": [userID: [userName, "Accept"]]
                                           ])
                    let alarm = Alarm(id: newAlarm.documentID, time: time, sound: sound, alarmBody: alarmBody, repeatInterval: repeatInterval, groupID: groupId, groupName: groupName, participants: [userID: [userName, "Accept"]])
                    
                    scheduleAlarm(alarmTime: alarm.time.ISO8601Format(), alarmBody: alarmBody, alarmId: newAlarm.documentID, ringTone: sound, deviceToken: fcmToken)
                    
                    DispatchQueue.main.async {
                        completion(.success(alarm))
                    }
                    
                }
                catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func removeAlarm(documentID: String?) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        guard let documentID = documentID else { return }
        
        guard !ongoingDeletions.contains(documentID) else { return }
        ongoingDeletions.insert(documentID)
        
        Task {
            do {
                debugPrint("[removeAlarm] starts")
                let document = db.collection("UserData").document(userID).collection("alarms").document(documentID)
                if let groupId = try await document.getDocument().get("groupId") as? String {
                    // For sharing alarm
                    print("Remove alarm within a group alarm")
                    
                    let groupRef = db.collection("Groups")
                        .document(groupId)
                    
                    // Count - 1 for group
                    DispatchQueue.main.async {
                        groupRef.updateData([
                            "alarmCount": FieldValue.increment(Int64(-1))
                        ]) { error in
                            if let error = error {
                                print("Cannot -1 count alarm for group: \(error.localizedDescription)")
                            } else {
                                print("Alarm count successfully decremented.")
                            }
                        }
                    }
                    
                    let alarmDoc = try await db.collection("Alarm").document(documentID).getDocument()
                    guard let participants = alarmDoc.get("participants") as? [String: [String]] else {
                        ongoingDeletions.remove(documentID)
                        return
                    }
                    
                    for (participantID, _) in participants {
                        try await db.collection("UserData").document(participantID).collection("alarms").document(documentID).delete()
                        debugPrint("[removeAlarm] done for participant: \(participantID)")
                    }
                    
                    try await db.collection("Alarm").document(documentID).delete()
                } else {
                    // For removing alarm only for self
                    print("Remove alarm within just for u")
                    try await document.delete()
                }
                if selectedAlarm?.id == documentID {
                    selectedAlarm = nil
                }
                debugPrint("[removeAlarm] ends")
            } catch {
                debugPrint("Error removing alarm: \(error.localizedDescription)")
            }
            ongoingDeletions.remove(documentID)
        }
    }
    
    // MARK: LEGACY
    func addAlarmToParticipants(participants: [String: [String]], alarmId: String, alarm: Alarm, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            debugPrint("[addAlarmToParticipants] starts")
            do {
                for participant in participants {
                    try await db.collection("UserData").document(participant.key)
                        .collection("alarms")
                        .document(alarmId)
                        .setData([
                                  "groupId": alarm.groupID ?? "",
                                  "isOn": alarm.isOn ?? true
                                 ])
                    debugPrint("[addAlarmToParticipants] done for \(participant.key)")
                }
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            }
            catch {
                debugPrint("[addAlarmToParticipants] error \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func addAlarmToParticipant(alarmId: String, groupId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            debugPrint("[addAlarmToParticipants] starts")
            do {
                try await db.collection("UserData").document(userID)
                    .collection("alarms")
                    .document(alarmId)
                    .setData([
                              "groupId": groupId,
                              "isOn": true
                             ])
                
                let documentRef = db.collection("Alarm").document(alarmId)
                let document = try await documentRef.getDocument()
                if var participants = document.data()?["participants"] as? [String: [String]] {
                    // Update the status for the given userID
                    if var participantInfo = participants[userID] {
                        participantInfo[1] = "Accept" // Assuming the status is the second item in the array
                        participants[userID] = participantInfo
                        
                        // Update the document with the modified participants dictionary
                        try await documentRef.setData(["participants": participants], merge: true)
                    } else {
                        print("User ID not found in participants")
                    }
                } else {
                    print("Participants field is missing or has an unexpected format")
                }
                
                debugPrint("[addAlarmToParticipant] done for \(userID)")
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            }
            catch {
                debugPrint("[addAlarmToParticipant] error \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func rejectAlarm(alarmId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                let documentRef = db.collection("Alarm").document(alarmId)
                let document = try await documentRef.getDocument()
                if var participants = document.data()?["participants"] as? [String: [String]] {
                    // Update the status for the given userID
                    if var participantInfo = participants[userID] {
                        participantInfo[1] = "Rejected" // Assuming the status is the second item in the array
                        participants[userID] = participantInfo
                        
                        // Update the document with the modified participants dictionary
                        try await documentRef.setData(["participants": participants], merge: true)
                    } else {
                        print("User ID not found in participants")
                    }
                } else {
                    print("Participants field is missing or has an unexpected format")
                }
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                debugPrint("[addAlarmToParticipant] error \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func editAlarm(alarmId: String?, updates: [String: Any]) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        if let alarmId = alarmId {
            Task {
                do {
                    let document = db.collection("UserData").document(userID).collection("alarms").document(alarmId)
                    if try await document.getDocument().get("groupId") is String {
                        // For sharing alarm
                        debugPrint("[editAlarm] starts")
                        try await db.collection("Alarm")
                            .document(alarmId)
                            .updateData(updates)
                        if let participants = updates["participants"] as? [String] {
                            for participantID in participants {
                                try await db.collection("UserData").document(participantID)
                                    .collection("alarms")
                                    .document(alarmId)
                                    .updateData(updates)
                            }
                        }
                    } else {
                        // For editing alarm only for self
                        try await document.updateData(updates)
                    }
                    if let newTime = updates["time"] as? Date {
                        if let index = alarms.firstIndex(where: { $0.id == alarmId }) {
                            alarms[index].time = newTime
                        }
                    }
                    
                    if selectedAlarm?.id == alarmId {
                        selectedAlarm = nil
                    }
                    debugPrint("[editAlarm] ends")
                }
                catch {
                    debugPrint("[editAlarm] error \(error.localizedDescription)")
                }
            }
        } else {
            print("No alarmID")
        }
    }
    
    func toggleAlarm(alarmId: String?, value: Bool) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        if let alarmId = alarmId {
            Task {
                let document = db.collection("UserData").document(userID).collection("alarms").document(alarmId)
                document.updateData(["isOn": value])
            }
        }
    }
    
}

// For AlarmView
extension AlarmsViewModel {
    func ifUserStopped(participants: [String: [String]]) -> Bool {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return false }
        return participants[userID]![1] == "Stopped"
    }
    
    func setUserStop(alarmId: String?, participants: [String: [String]]) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        if let alarmId = alarmId {
            var newParticipants = participants
            newParticipants[userID]![1] = "Stopped"
            Task {
                let document = db.collection("Alarm").document(alarmId)
                document.updateData(["participants": newParticipants])
            }
        }
    }
    
    func ifAllUserStop(alarmId: String?, participants: [String: [String]]) -> Bool {
        for (_, status) in participants {
            if status[1] != "Stopped" {
                return false
            }
        }
        return true
    }
}

// For Alarm Listener
extension AlarmsViewModel {
    func startListeningAlarm(forDocument alarmId: String) {
        // Set up the listener
        listener = db.collection("Alarm").document(alarmId).addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error listening to changes: \(error)")
                return
            }
            
            if let document = documentSnapshot, document.exists {
                if let participants = document.data()?["participants"] as? [String: [String]] {
                    if let index = self.alarms.firstIndex(where: { $0.id == alarmId }) {
                        self.alarms[index].participants = participants
                        self.selectedAlarm?.participants = participants
                        print("Participants updated for alarm \(alarmId): \(participants)")
                    }
                } else {
                    print("Participants field does not exist or is not in the expected format.")
                }
            } else {
                print("Document does not exist.")
                stopListening()
            }
        }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
//    
//    deinit {
//        stopListening()
//    }
}

extension AlarmsViewModel {
    func startListeningAlarms() {
        print("Start Listening")
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        alarmsListener = db.collection("UserData").document(userID).collection("alarms").addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error listening to collection changes: \(error)")
                return
            }
            
            querySnapshot?.documentChanges.forEach { change in
                switch change.type {
                case .added:
                    self.handleDocumentAdded(change.document)
                case .modified:
                    self.handleDocumentModified(change.document)
                case .removed:
                    self.handleDocumentRemoved(change.document)
                }
            }
        }
    }
    
    private func handleDocumentAdded(_ document: DocumentSnapshot) {
        if document.get("groupId") is String {
            // Fetch the alarm data from the Alarm collection using the document's ID
            if let isOn = document.get("isOn") as? Bool {
                fetchAlarmData(from: document.documentID, isOn: isOn)
            }
        } else {
            // Directly convert the document data to Alarm
            if let alarm = try? document.data(as: Alarm.self) {
                print("Alarm ID \(alarm.id ?? "NOID")")
                self.alarms.append(alarm)
                self.groupNames.insert(alarm.groupName ?? "Just For You")
                if let id = alarm.id {
                    AppDelegate.shared.scheduleLocalNotification(id: id, title: "SharingAlarm", body: alarm.alarmBody, alarmTime: alarm.time, sound: alarm.sound, ringtoneURL: alarm.ringtoneURL)
                }
            }
        }
    }
    
    private func handleDocumentModified(_ document: DocumentSnapshot) {
        if let index = self.alarms.firstIndex(where: { $0.id == document.documentID }) {
            if document.get("groupId") is String {
                // Fetch the updated alarm data from the Alarm collection
                if let isOn = document.get("isOn") as? Bool {
                    fetchAlarmData(from: document.documentID, index: index, isOn: isOn)
                }
            } else {
                // Directly update the existing alarm
                if let updatedAlarm = try? document.data(as: Alarm.self) {
                    self.alarms[index] = updatedAlarm
                }
            }
        }
    }
    
    private func handleDocumentRemoved(_ document: DocumentSnapshot) {
        if let index = self.alarms.firstIndex(where: { $0.id == document.documentID }) {
            self.alarms.remove(at: index)
        }
        if let index = self.ongoingAlarms.firstIndex(where: { $0.id == document.documentID }) {
            self.ongoingAlarms.remove(at: index)
        }
        self.timerViewModels[document.documentID]?.stopTimer()
        AppDelegate.shared.cancelScheduledLocalNotification(id: document.documentID)
    }
    
    private func fetchAlarmData(from documentID: String, index: Int? = nil, isOn: Bool) {
        let db = Firestore.firestore()
        db.collection("Alarm").document(documentID).getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists else { return }
            if var alarm = try? document.data(as: Alarm.self) {
                alarm.isOn = isOn
                if let index = index {
                    // Update the existing alarm
                    self.alarms[index] = alarm
                } else {
                    // Add the new alarm
                    self.alarms.append(alarm)
                    self.groupNames.insert(alarm.groupName ?? "Just For You")
                    if let id = alarm.id {
                        AppDelegate.shared.scheduleLocalNotification(id: id, title: "SharingAlarm", body: alarm.alarmBody, alarmTime: alarm.time, sound: alarm.sound, ringtoneURL: alarm.ringtoneURL)
                    }
                }
            }
        }
    }
    
    func stopListeningAlarms() {
        print("Stop Listening")
        alarmsListener?.remove()
        alarmsListener = nil
    }

//    deinit {
//        stopListening()
//    }
}

extension AlarmsViewModel {

    func startLongVibration() {
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

struct AlarmRequest: Codable {
    let alarmTime: String
    let alarmBody: String
    let alarmId: String
    let ringTone: String
    let deviceToken: String
}

extension AlarmsViewModel {
    func scheduleAlarm(alarmTime: String, alarmBody: String, alarmId: String, ringTone: String, deviceToken: String) {
        // https://alarm-scheduler.fly.dev/scheduleAlarm
        // http://192.168.7.39:3000/scheduleAlarm
        guard let url = URL(string: "https://alarm-scheduler.fly.dev/scheduleAlarm") else { return }
        print("Schedule alarm now within https://alarm-scheduler.fly.dev/scheduleAlarm")
        
        let alarmRequest = AlarmRequest(alarmTime: alarmTime, alarmBody: alarmBody, alarmId: alarmId, ringTone: ringTone, deviceToken: deviceToken)
        
        // Convert to JSON data
        guard let jsonData = try? JSONEncoder().encode(alarmRequest) else { return }
        
        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Make the network request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error scheduling alarm: \(error.localizedDescription)")
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Alarm scheduled successfully")
            } else {
                print("Failed to schedule alarm")
            }
        }.resume()
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

struct Ringtone: Hashable, Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var filename: String
    var price: Int
}

extension AlarmsViewModel {
    func fetchRingtoneList() {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else { return }
        Task {
            debugPrint("[fetchRingtone] starts")
            do {
                let userSnapshot = try await db.collection("UserData").document(userID).getDocument()
                if let unlockedRingtones = userSnapshot.data()?["unlockedRingtones"] as? [String] {
                    let querySnapshot = try await db.collection("Ringtones").getDocuments()
                    if !querySnapshot.isEmpty {
                        for document in querySnapshot.documents {
                            let ringtone = try document.data(as: Ringtone.self)
                            if unlockedRingtones.contains(document.documentID) {
                                self.ringtones.append(ringtone)
                            } else {
                                self.premiumRingtones.append(ringtone)
                            }
                        }
                    }
                    debugPrint("[fetchRingtone] ends")
                } else {
                    self.ringtones = []
                    self.premiumRingtones = []
                }
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
}
