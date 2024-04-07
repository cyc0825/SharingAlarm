//
//  FriendsViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import Foundation
import CloudKit



struct FriendRequest: Hashable{
    var recordID: CKRecord.ID
    var senderID: String
    var senderName: String
}

struct User: Hashable{
    var recordID: CKRecord.ID
    var name: String
    var uid: String
}

class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [FriendRequest] = []
    
    func fetchUsernames(for senderID: String, completion: @escaping (String) -> Void) {
        let predicate = NSPredicate(format: "uid == %@", senderID)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            DispatchQueue.main.async {
                guard let record = records?.first, error == nil else {
                    print("Error fetching user data: \(error?.localizedDescription ?? "No Friend Request")")
                    return
                }
                if let name = record["name"] as? String {
                    completion(name)
                }
            }
        }
    }
    
    func removeFriendRequest(_ request: FriendRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = request.recordID
        CKContainer.default().publicCloudDatabase.delete(withRecordID: recordID) { (recordID, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func addFriendship(fromRequest request: FriendRequest, receiverID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let newFriendship = CKRecord(recordType: "Friendship")
        newFriendship["userID1"] = receiverID
        newFriendship["userID2"] = request.senderID
        
        CKContainer.default().publicCloudDatabase.save(newFriendship) { (record, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func searchRequest() {
        guard UserDefaults.standard.value(forKey: "uid") != nil else { return }
        let predicate = NSPredicate(format: "receiverID == %@", UserDefaults.standard.value(forKey: "uid") as! String)
        let query = CKQuery(recordType: "FriendRequest", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                guard record["senderID"] != nil else {
                    print("SenderID is nil")
                    return
                }
                print(record["senderID"]!, "Succeed")
                self.fetchUsernames(for: record["senderID"] as! String) { name in
                    self.friendRequests.append(FriendRequest(recordID: recordID, senderID: record["senderID"] as! String, senderName: name))
                }
            case .failure(let error):
                print("Failed to fetch record: \(error.localizedDescription)")
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
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func searchFriends(query: String) {
        let predicate = NSPredicate(format: "uid BEGINSWITH %@", query)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        
        var newResults: [CKRecord] = []
        
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                self.friends.append(User(recordID: recordID, name: record["name"] as? String ?? "Unknown", uid: record["uid"] as? String ?? "Unknown"))
            case .failure(let error):
                print("Failed to fetch record: \(error.localizedDescription)")
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
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func sendFriendRequest(to userRecord: CKRecord) {
        // Implement the logic to send a friend request.
        // This might involve creating a new record in a "FriendRequests" record type
        // and setting the appropriate fields such as requesterId, requesteeId, etc.
        print("Friend request sent to: \(userRecord["uid"] as? String ?? "Unknown")")
    }
}
