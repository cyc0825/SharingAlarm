//
//  FriendsViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import Foundation
import CloudKit
import FirebaseFirestore

struct FriendReference: Codable, Identifiable {
    @DocumentID var id: String?
    var friendRef: AppUser
    var timestamp: Date
}

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [FriendReference] = []
    @Published var friendSearchResults: [AppUser] = []
    @Published var friendRequests: [FriendReference] = []
    @Published var ownRequests: [FriendReference] = []
    
    private var db = Firestore.firestore()
    
    func fetchOwnRequest() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        db.collection("Friends").document(userID)
            .collection("ownRequests")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching own requests: \(error.localizedDescription)")
                    return
                }

                if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                    for document in querySnapshot.documents {
                        let id = document.documentID
                        let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue() ?? Date()

                        if let friendRef = document.get("friendRef") as? DocumentReference {
                            Task {
                                do {
                                    let appUser = try await friendRef.getDocument(as: AppUser.self)
                                    self.ownRequests.append(FriendReference(id: id, friendRef: appUser, timestamp: timestamp))
                                }
                                catch {
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    }
                } else {
                    self.ownRequests = []
                }
            }
    }
    
    func fetchFriendsRequest() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        print("Start fetching friend Request for \(userID)")
        db.collection("Friends").document(userID)
            .collection("friendRequests")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching friend requests: \(error.localizedDescription)")
                    return
                }

                if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                    for document in querySnapshot.documents {
                        let id = document.documentID
                        let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue() ?? Date()

                        if let friendRef = document.get("friendRef") as? DocumentReference {
                            Task {
                                do {
                                    print(friendRef)
                                    let appUser = try await friendRef.getDocument(as: AppUser.self)
                                    print(appUser)
                                    self.friendRequests.append(FriendReference(id: id, friendRef: appUser, timestamp: timestamp))
                                }
                                catch {
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    }
                } else {
                    self.friendRequests = []
                }
            }
    }
    
    func fetchFriends() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        db.collection("Friends").document(userID)
            .collection("friends")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching friends: \(error.localizedDescription)")
                    return
                }
                
                if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                    for document in querySnapshot.documents {
                        let id = document.documentID
                        let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue() ?? Date()

                        if let friendRef = document.get("friendRef") as? DocumentReference {
                            Task {
                                do {
                                    let appUser = try await friendRef.getDocument(as: AppUser.self)
                                    self.friends.append(FriendReference(id: id, friendRef: appUser, timestamp: timestamp))
                                }
                                catch {
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    }
                } else {
                    self.friends = []
                }
            }
    }
    
    // User1 sends FR to User2
    func saveFriendRequest(user2ID: String) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                try await db.collection("Friends").document(userID)
                    .collection("ownRequests")
                    .addDocument(data: ["friendRef": db.collection("UserData").document(user2ID),
                                        "timestamp": Date.now])
                
                try await db.collection("Friends").document(user2ID)
                    .collection("friendRequests")
                    .addDocument(data: ["friendRef": db.collection("UserData").document(userID),
                                        "timestamp": Date.now])
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func saveFriendShip(fromRequest request: FriendReference) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                try await db.collection("Friends").document(userID)
                    .collection("friends")
                    .addDocument(data: ["friendRef": request.friendRef,
                                        "timestamp": Date.now])
                
                try await db.collection("Friends").document(request.friendRef.uid)
                    .collection("friends")
                    .addDocument(data: ["friendRef": db.collection("users").document(userID),
                                        "timestamp": Date.now])
                try await print("1st try wait")
                try await print("2st try wait")
                print("after try wait")
            }
            catch {
                print(error.localizedDescription)
            }
        }
        print("after Task")
    }
    
    func fetchFriendSearch(query: String) {
        Task {
            do {
                let documentSnapshot = try await db.collection("UserData").whereField("uid", isGreaterThan: query).getDocuments()
                if !documentSnapshot.isEmpty {
                    for document in documentSnapshot.documents {
                        let id = document.documentID
                        if let uid = document.get("uid") as? String, let name = document.get("name") as? String {
                            let appUser = AppUser(id: id, name: name, uid: uid)
                            self.friendSearchResults.append(appUser)
                        }
                    }
                }
                else {
                    self.friendSearchResults = []
                }
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func removeFriendRequest(fromRequest request: FriendReference) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                try await db.collection("Friends").document(userID)
                    .collection("friendRequests")
                    .document(request.id!)
                    .delete()
                print("Trying to remove FR for \(request.friendRef.id!)")
                try await db.collection("Friends").document(request.friendRef.id!)
                    .collection("ownRequests")
                    .document(request.id!)
                    .delete()
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
}
