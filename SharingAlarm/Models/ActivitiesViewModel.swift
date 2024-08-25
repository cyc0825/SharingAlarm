//
//  ActivitiesViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/11.
//

import Foundation
import CloudKit
import FirebaseFirestore

struct Activity: Hashable, Codable, Identifiable  {
    @DocumentID var id: String?
    var from: Date
    var to: Date
    var name: String
    var participants: [AppUser]
    var alarmCount: Int
    
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.id == rhs.id
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//struct ActivityReference: Hashable, Codable, Identifiable {
//    static func == (lhs: ActivityReference, rhs: ActivityReference) -> Bool {
//        return lhs.id == rhs.id
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(timestamp)
//    }
//    
//    @DocumentID var id: String?
//    var activityRef: Activity
//    var timestamp: Date
//}

@MainActor
class ActivitiesViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    
    private var db = Firestore.firestore()
    
    init() {
        fetchActivity()
    }
    
    func fetchActivity() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                debugPrint("[fetchActivities] starts")
                let querySnapshot = try await db.collection("UserData").document(userID)
                    .collection("activities")
                    .getDocuments()
                
                if !querySnapshot.isEmpty {
                    for document in querySnapshot.documents {
                        let id = document.documentID
                        // let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue() ?? Date()
                        if let activityRef = document.get("activityRef") as? DocumentReference {
                            Task {
                                do {
                                    let activityData = try await activityRef.getDocument()
                                    var resolvedParticipants: [AppUser] = []
                                    let participantsCollectionRef = activityRef.collection("participants")
                                    let participantsSnapshot = try await participantsCollectionRef.getDocuments()
                                    for doc in participantsSnapshot.documents {
                                        if let userRef = doc.get("userRef") as? DocumentReference {
                                            let user = try await userRef.getDocument(as: AppUser.self)
                                            resolvedParticipants.append(user)
                                        }
                                    }
                                    if !self.activities.contains(where: { $0.id == id }) {
                                        let activity = Activity(id: id,
                                                                from: activityData["from"] as? Date ?? Date(),
                                                                to: activityData["to"] as? Date ?? Date(),
                                                                name: activityData["name"] as? String ?? "",
                                                                participants: resolvedParticipants,
                                                                alarmCount: activityData["alarmCount"] as? Int ?? 0)
                                        self.activities.append(activity)
                                    }
                                }
                                catch {
                                    debugPrint("[fetchFriends] error")
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    }
                } else {
                    self.activities = []
                }
            }
            catch {
                print(error.localizedDescription)
            }
            debugPrint("[fetchActivities] done")
        }
    }
    
    func addActivity(name: String, startDate: Date, endDate: Date, participants: [AppUser], completion: @escaping (Result<Activity, Error>) -> Void) {
        // guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                debugPrint("[addActivity] starts")
                let activityRef = try await db.collection("Activity")
                    .addDocument(data: ["from": startDate,
                                        "to": endDate,
                                        "name": name])
                
//                try await db.collection("Activity")
//                    .document(activityRef.documentID)
//                    .collection("participants")
//                    .addDocument(data: ["userRef": db.collection("UserData").document(userID)])
//                try await db.collection("UserData").document(userID)
//                    .collection("activities")
//                    .addDocument(data: ["activityRef": activityRef,
//                                        "timestamp": Date.now])
//                debugPrint("[addActivity] done for \(userID)")
//                
                addParticipant(activityId: activityRef.documentID, participants: participants) { result in
                    switch result {
                    case .success(_):
                        completion(.success(Activity(id: activityRef.documentID, from: startDate, to: endDate, name: name, participants: participants, alarmCount: 0)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            catch {
                debugPrint("[addActivity] error \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func convertUserToUID(Users: [AppUser]) -> [String] {
        var result: [String] = []
        for user in Users {
            result.append(user.uid)
        }
        return result
    }
    
    func editActivity(activityId: String, name: String, startDate: Date, endDate: Date, newParticipants: [AppUser], completion: @escaping (Result<[AppUser], Error>) -> Void) {
        Task {
            do {
                debugPrint("[addActivity] starts")
                try await db.collection("Activity")
                    .document(activityId)
                    .setData(["from": startDate,
                              "to": endDate,
                              "name": name])
                addParticipant(activityId: activityId, participants: newParticipants) { result in
                    switch result {
                    case .success(_):
                        completion(.success(newParticipants))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func removeActivity(activity: Activity, completion: @escaping (Result<Bool, Error>) -> Void){
        // guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        
        Task {
            debugPrint("[removeActivity] starts")
            do {
                for participant in activity.participants{
                    try await db.collection("UserData").document(participant.id!)
                        .collection("activities")
                        .document(activity.id!)
                        .delete()
                }
                
                if let activityId = activity.id {
                    let activityRef = db.collection("Activity").document(activityId)
                    let subcollection = activityRef.collection("participants")
                    let subcollectionDocs = try await subcollection.getDocuments()
                    for doc in subcollectionDocs.documents {
                        try await doc.reference.delete()
                    }
                    try await activityRef.delete()
                }
            }
            catch {
                debugPrint("[removeActivity] error \(error.localizedDescription)")
                completion(.failure(error))
            }
            debugPrint("[removeActivity] ends")
            completion(.success(true))
        }
    }
    
    func addParticipant(activityId: String, participants: [AppUser], completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            debugPrint("[addParticipant] starts")
            do {
                let activityRef = db.collection("Activity").document(activityId)
                for participant in participants {
                    if let userId = participant.id {
                        try await db.collection("Activity")
                            .document(activityRef.documentID)
                            .collection("participants")
                            .document(participant.id!)
                            .setData(["userRef": db.collection("UserData").document(participant.id!)])
                    
                        try await db.collection("UserData").document(userId)
                            .collection("activities")
                            .document(activityRef.documentID)
                            .setData(["activityRef": activityRef,
                                      "timestamp": Date.now])
                    }
                    debugPrint("[addParticipant] done for \(participant.uid)")
                }
                completion(.success(true))
            }
            catch {
                debugPrint("[addParticipant] error \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func removeParticipant(activityId: String, participantId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            debugPrint("[removeParticipant] starts")
            do {
                try await db.collection("Activity")
                    .document(activityId)
                    .collection("participants")
                    .document(participantId).delete()
                
                try await db.collection("UserData").document(participantId)
                    .collection("activities")
                    .document(activityId)
                    .delete()
                completion(.success(true))
            }
            catch {
                debugPrint("[removeParticipant] error \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

extension ActivitiesViewModel {
    static func withSampleData() -> ActivitiesViewModel {
        let sampleViewModel = ActivitiesViewModel()
        sampleViewModel.activities.append(Activity(from: Date(), to: Date(), name: "test", participants: [], alarmCount: 0))
        
        return sampleViewModel
    }
}
