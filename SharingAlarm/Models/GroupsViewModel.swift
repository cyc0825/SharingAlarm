//
//  GroupsViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/11.
//

import Foundation
import CloudKit
import FirebaseFirestore

struct Groups: Hashable, Codable, Identifiable  {
    @DocumentID var id: String?
    var from: Date
    var to: Date
    var name: String
    var participants: [AppUser]
    var alarmCount: Int
    
    static func == (lhs: Groups, rhs: Groups) -> Bool {
        return lhs.id == rhs.id
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//struct GroupReference: Hashable, Codable, Identifiable {
//    static func == (lhs: GroupReference, rhs: GroupReference) -> Bool {
//        return lhs.id == rhs.id
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(timestamp)
//    }
//    
//    @DocumentID var id: String?
//    var GroupRef: Groups
//    var timestamp: Date
//}

@MainActor
class GroupsViewModel: ObservableObject {
    @Published var groups: [Groups] = []
    
    private var db = Firestore.firestore()
    
    init() {
//        fetchGroup()
    }
    
    func fetchGroup() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                debugPrint("[fetchGroups] starts")
                let querySnapshot = try await db.collection("UserData").document(userID)
                    .collection("groups")
                    .getDocuments()
                
                if !querySnapshot.isEmpty {
                    for document in querySnapshot.documents {
                        let id = document.documentID
                        // let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue() ?? Date()
                        if let GroupRef = document.get("groupRef") as? DocumentReference {
                            Task {
                                do {
                                    let GroupData = try await GroupRef.getDocument()
                                    var resolvedParticipants: [AppUser] = []
                                    let participantsCollectionRef = GroupRef.collection("participants")
                                    let participantsSnapshot = try await participantsCollectionRef.getDocuments()
                                    for doc in participantsSnapshot.documents {
                                        if let userRef = doc.get("userRef") as? DocumentReference {
                                            let user = try await userRef.getDocument(as: AppUser.self)
                                            resolvedParticipants.append(user)
                                        }
                                    }
                                    if !self.groups.contains(where: { $0.id == id }) {
                                        let Groups = Groups(id: id,
                                                                from: GroupData["from"] as? Date ?? Date(),
                                                                to: GroupData["to"] as? Date ?? Date(),
                                                                name: GroupData["name"] as? String ?? "",
                                                                participants: resolvedParticipants,
                                                                alarmCount: GroupData["alarmCount"] as? Int ?? 0)
                                        self.groups.append(Groups)
                                    }
                                }
                                catch {
                                    debugPrint("[fetchGroups] error")
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    }
                } else {
                    self.groups = []
                }
            }
            catch {
                print(error.localizedDescription)
            }
            debugPrint("[fetchGroups] done")
        }
    }
    
    func addGroup(name: String, startDate: Date, endDate: Date, participants: [AppUser], completion: @escaping (Result<Groups, Error>) -> Void) {
        // guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                debugPrint("[addGroup] starts")
                let groupRef = try await db.collection("Groups")
                    .addDocument(data: ["from": startDate,
                                        "to": endDate,
                                        "name": name])
                
//                try await db.collection("Groups")
//                    .document(GroupRef.documentID)
//                    .collection("participants")
//                    .addDocument(data: ["userRef": db.collection("UserData").document(userID)])
//                try await db.collection("UserData").document(userID)
//                    .collection("groups")
//                    .addDocument(data: ["GroupRef": GroupRef,
//                                        "timestamp": Date.now])
//                debugPrint("[addGroup] done for \(userID)")
//                
                addParticipant(groupId: groupRef.documentID, participants: participants) { result in
                    switch result {
                    case .success(_):
                        completion(.success(Groups(id: groupRef.documentID, from: startDate, to: endDate, name: name, participants: participants, alarmCount: 0)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            catch {
                debugPrint("[addGroup] error \(error.localizedDescription)")
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
    
    func editGroup(groupId: String, name: String, startDate: Date, endDate: Date, newParticipants: [AppUser], completion: @escaping (Result<[AppUser], Error>) -> Void) {
        Task {
            do {
                debugPrint("[addGroup] starts")
                try await db.collection("Groups")
                    .document(groupId)
                    .setData(["from": startDate,
                              "to": endDate,
                              "name": name])
                addParticipant(groupId: groupId, participants: newParticipants) { result in
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
    
    func removeGroup(group: Groups, completion: @escaping (Result<Bool, Error>) -> Void){
        // guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        
        Task {
            debugPrint("[removeGroup] starts")
            do {
                for participant in group.participants{
                    try await db.collection("UserData").document(participant.id!)
                        .collection("groups")
                        .document(group.id!)
                        .delete()
                }
                
                if let groupId = group.id {
                    let GroupRef = db.collection("Groups").document(groupId)
                    let subcollection = GroupRef.collection("participants")
                    let subcollectionDocs = try await subcollection.getDocuments()
                    for doc in subcollectionDocs.documents {
                        try await doc.reference.delete()
                    }
                    try await GroupRef.delete()
                }
            }
            catch {
                debugPrint("[removeGroup] error \(error.localizedDescription)")
                completion(.failure(error))
            }
            debugPrint("[removeGroup] ends")
            completion(.success(true))
        }
    }
    
    func addParticipant(groupId: String, participants: [AppUser], completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            debugPrint("[addParticipant] starts")
            do {
                let groupRef = db.collection("Groups").document(groupId)
                for participant in participants {
                    if let userId = participant.id {
                        try await db.collection("Groups")
                            .document(groupRef.documentID)
                            .collection("participants")
                            .document(participant.id!)
                            .setData(["userRef": db.collection("UserData").document(participant.id!)])
                    
                        try await db.collection("UserData").document(userId)
                            .collection("groups")
                            .document(groupRef.documentID)
                            .setData(["groupRef": groupRef,
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
    
    func removeParticipant(groupId: String, participantId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            debugPrint("[removeParticipant] starts")
            do {
                try await db.collection("Groups")
                    .document(groupId)
                    .collection("participants")
                    .document(participantId).delete()
                
                try await db.collection("UserData").document(participantId)
                    .collection("groups")
                    .document(groupId)
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

extension GroupsViewModel {
    static func withSampleData() -> GroupsViewModel {
        let sampleViewModel = GroupsViewModel()
        sampleViewModel.groups.append(Groups(from: Date(), to: Date(), name: "test", participants: [], alarmCount: 0))
        
        return sampleViewModel
    }
}
