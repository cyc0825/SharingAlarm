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
    
    init() {
        fetchFriends()
        fetchOwnRequest()
        fetchFriendsRequest()
    }
    
    func fetchOwnRequest() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                self.ownRequests = []
                let querySnapshot = try await db.collection("Friends").document(userID)
                    .collection("ownRequests")
                    .getDocuments()
                        
                if !querySnapshot.isEmpty {
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
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func fetchFriendsRequest() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                print("Start fetching friend Request for \(userID)")
                self.friendRequests = []
                let querySnapshot = try await db.collection("Friends").document(userID)
                    .collection("friendRequests")
                    .getDocuments()
                        
                        
                if !querySnapshot.isEmpty {
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
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func fetchFriends() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            do {
                debugPrint("[fetchFriends] starts")
                let querySnapshot = try await db.collection("Friends").document(userID)
                    .collection("friends")
                    .getDocuments()
                       
                if !querySnapshot.isEmpty {
                    for document in querySnapshot.documents {
                        let id = document.documentID
                        let timestamp = (document.get("timestamp") as? Timestamp)?.dateValue() ?? Date()
                        
                        if let friendRef = document.get("friendRef") as? DocumentReference {
                            Task {
                                do {
                                    let appUser = try await friendRef.getDocument(as: AppUser.self)
                                    if !self.friends.contains(where: { $0.friendRef.uid == appUser.uid }) {
                                        self.friends.append(FriendReference(id: id, friendRef: appUser, timestamp: timestamp))
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
                    self.friends = []
                }
            }
            catch {
                print(error.localizedDescription)
            }
            debugPrint("[fetchFriends] done")
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
                debugPrint("[SaveFriendship] starts")
                let currentUserRef = db.collection("UserData").document(userID)
                let friendUserRef = db.collection("UserData").document(request.friendRef.id ?? "")
                try await db.collection("Friends").document(userID)
                    .collection("friends")
                    .addDocument(data: ["friendRef": friendUserRef,
                                        "timestamp": Date.now])
                
                try await db.collection("Friends").document(request.friendRef.id!)
                    .collection("friends")
                    .addDocument(data: ["friendRef": currentUserRef,
                                        "timestamp": Date.now])
                debugPrint("[SaveFriendship] done")
            }
            catch {
                debugPrint("[SaveFriendship] error \(error.localizedDescription)")
            }
        }
    }
    
    func fetchFriendSearch(query: String) {
        Task {
            do {
                self.friendSearchResults = []
                let documentSnapshot: QuerySnapshot
                if query != "" {
                    documentSnapshot = try await db.collection("UserData").whereField("uid", isEqualTo: query).getDocuments()
                } else {
                    documentSnapshot = try await db.collection("UserData").getDocuments()
                }
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
        
        let userRef = db.collection("UserData").document(userID)
        let friendRef = db.collection("UserData").document(request.friendRef.id!)
        
        Task {
            debugPrint("[removeFriendRequest] starts")
            let friendRequestsQuery = db.collection("Friends").document(userID)
                .collection("friendRequests")
                .whereField("friendRef", isEqualTo: friendRef)
            
            do {
                let querySnapshot = try await friendRequestsQuery.getDocuments()
                for document in querySnapshot.documents {
                    try await document.reference.delete()
                }
                print("Removed friend request from 'friendRequests'")
            } catch {
                debugPrint("Error removing friend request from 'friendRequests': \(error.localizedDescription)")
            }
            
            // Query and delete from the 'ownRequests' collection
            let ownRequestsQuery = db.collection("Friends").document(request.friendRef.id!)
                .collection("ownRequests")
                .whereField("friendRef", isEqualTo: userRef)
            
            do {
                let querySnapshot = try await ownRequestsQuery.getDocuments()
                for document in querySnapshot.documents {
                    try await document.reference.delete()
                }
                print("Removed friend request from 'ownRequests'")
            } catch {
                debugPrint("Error removing friend request from 'ownRequests': \(error.localizedDescription)")
            }
            
            debugPrint("[removeFriendRequest] ends")
        }
    }
    
    func removeFriend(for friendIndex: Int) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        
        let userRef = db.collection("UserData").document(userID)
        let friendRef = db.collection("UserData").document(friends[friendIndex].friendRef.id!)
        
        Task {
            debugPrint("[removeFriend] starts")
            let friendRequestsQuery = db.collection("Friends").document(userID)
                .collection("friends")
                .whereField("friendRef", isEqualTo: friendRef)
            
            do {
                let querySnapshot = try await friendRequestsQuery.getDocuments()
                for document in querySnapshot.documents {
                    try await document.reference.delete()
                }
                print("Removed friend for 'user'")
            } catch {
                debugPrint("Error removing friend request for 'user': \(error.localizedDescription)")
            }
            
            // Query and delete from the 'ownRequests' collection
            let ownRequestsQuery = db.collection("Friends").document(friends[friendIndex].friendRef.id!)
                .collection("friends")
                .whereField("friendRef", isEqualTo: userRef)
            
            do {
                let querySnapshot = try await ownRequestsQuery.getDocuments()
                for document in querySnapshot.documents {
                    try await document.reference.delete()
                }
                print("Removed friend for 'friend'")
            } catch {
                debugPrint("Error removing friend for 'friend': \(error.localizedDescription)")
            }
            friends.remove(at: friendIndex)
            debugPrint("[removeFriend] ends")
        }
    }
}
