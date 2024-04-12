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
    @Published var friendSearchResults: [User] = []
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
        let predicate = NSPredicate(format: "senderID == %@", request.senderID)
        let query = CKQuery(recordType: "FriendRequest", predicate: predicate)
        
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let records = records else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No Records Found", code: 0, userInfo: nil)))
                }
                return
            }
            
            let recordIDs = records.map { $0.recordID }
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
                
            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
            
            CKContainer.default().publicCloudDatabase.add(operation)
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
    
    func removeFriendship(recordID: CKRecord.ID, completion: @escaping (Result<Void, Error>) -> Void) {
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
    
    func searchRequest() {
        guard let uid = UserDefaults.standard.value(forKey: "uid") as? String else { return }
        let lastFetchDate = UserDefaults.standard.value(forKey: "lastFriendRequestFetchDate") as? Date ?? Date.distantPast
        
        let predicate = NSPredicate(format: "modificationDate > %@ AND receiverID == %@", argumentArray: [lastFetchDate, uid])
        let query = CKQuery(recordType: "FriendRequest", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        var mostRecentUpdate: Date = lastFetchDate
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                guard let senderID = record["senderID"] as? String else {
                    print("SenderID is nil")
                    return
                }
                self.fetchUsernames(for: senderID) { name in
                    guard !self.friendRequests.contains(where: { $0.senderID == senderID }) else {
                        return
                    }
                    if let modificationDate = record.modificationDate, modificationDate > mostRecentUpdate {
                        mostRecentUpdate = modificationDate
                    }
                    let newRequest = FriendRequest(recordID: recordID, senderID: senderID, senderName: name)
                    self.friendRequests.append(newRequest)
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
        UserDefaults.standard.set(mostRecentUpdate, forKey: "lastFriendRequestFetchDate")
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func searchFriends(query: String) {
        let predicate = NSPredicate(format: "uid BEGINSWITH %@", query)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                DispatchQueue.main.async {
                    self.friendSearchResults.append(User(recordID: recordID, name: record["name"] as? String ?? "Unknown", uid: record["uid"] as? String ?? "Unknown"))
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
    
    func fetchFriends() {
        guard let currentUserID = UserDefaults.standard.value(forKey: "uid") as? String else { return }
        let lastFetchDate = UserDefaults.standard.value(forKey: "lastFriendFetchDate") as? Date ?? Date.distantPast
        
        let predicate1 = NSPredicate(format: "modificationDate > %@ AND userID1 == %@", argumentArray: [lastFetchDate, currentUserID])
        let predicate2 = NSPredicate(format: "modificationDate > %@ AND userID2 == %@", argumentArray: [lastFetchDate, currentUserID])
        
        let query1 = CKQuery(recordType: "Friendship", predicate: predicate1)
        let query2 = CKQuery(recordType: "Friendship", predicate: predicate2)
        
        let operation1 = CKQueryOperation(query: query1)
        let operation2 = CKQueryOperation(query: query2)
        var mostRecentUpdate: Date = lastFetchDate
        
        operation1.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                guard let userID = record["userID2"] as? String else {
                    print("userID is nil")
                    return
                }
                self.fetchUsernames(for: userID) { name in
                    guard !self.friends.contains(where: { $0.uid == userID }) else {
                        return
                    }
                    if let modificationDate = record.modificationDate, modificationDate > mostRecentUpdate {
                        mostRecentUpdate = modificationDate
                    }
                    
                    let newfriend = User(recordID: recordID, name: name, uid: userID)
                    self.friends.append(newfriend)
                }
            case .failure(let error):
                print("Failed to fetch record: \(error.localizedDescription)")
            }
        }
        
        operation2.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                guard let userID = record["userID1"] as? String else {
                    print("userID is nil")
                    return
                }
                self.fetchUsernames(for: userID) { name in
                    guard !self.friends.contains(where: { $0.uid == userID }) else {
                        return
                    }
                    if let modificationDate = record.modificationDate, modificationDate > mostRecentUpdate {
                        mostRecentUpdate = modificationDate
                    }
                    let newfriend = User(recordID: recordID, name: name, uid: userID)
                    self.friends.append(newfriend)
                }
            case .failure(let error):
                print("Failed to fetch record: \(error.localizedDescription)")
            }
        }
        
        operation1.queryResultBlock = { result in
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
        
        operation2.queryResultBlock = { result in
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
        UserDefaults.standard.set(mostRecentUpdate, forKey: "lastFriendFetchDate")
        CKContainer.default().publicCloudDatabase.add(operation1)
        CKContainer.default().publicCloudDatabase.add(operation2)
    }
    
    func sendFriendRequest(to userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard UserDefaults.standard.value(forKey: "uid") != nil else { return }
        let newFriendRequest = CKRecord(recordType: "FriendRequest")
        newFriendRequest["receiverID"] = userID
        newFriendRequest["senderID"] = UserDefaults.standard.value(forKey: "uid") as! String
        
        CKContainer.default().publicCloudDatabase.save(newFriendRequest) { (record, error) in
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
