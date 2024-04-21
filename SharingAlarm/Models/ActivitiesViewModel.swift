//
//  ActivitiesViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/11.
//

import Foundation
import CloudKit

struct Activity {
    var recordID: CKRecord.ID
    var from: Date
    var to: Date
    var name: String
    var participants: [User]
}

class ActivitiesViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    
    init() {
    }
    
    func fetchActivity() {
        let lastFetchDate = UserDefaults.standard.value(forKey: "lastActivityFetchDate") as? Date ?? Date.distantPast
        let predicate = NSPredicate(format: "modificationDate > %@", lastFetchDate as CVarArg)
        let query = CKQuery(recordType: "ActivityData", predicate: predicate)
        
        // You can also specify sorting if needed
        let sortDescriptor = NSSortDescriptor(key: "modificationDate", ascending: true)
        query.sortDescriptors = [sortDescriptor]
        let operation = CKQueryOperation(query: query)
        var mostRecentUpdate: Date = lastFetchDate
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                DispatchQueue.main.async {
                    guard !self.activities.contains(where: { $0.recordID == recordID }) else {
                        return
                    }
                    if let modificationDate = record.modificationDate, modificationDate > mostRecentUpdate {
                        mostRecentUpdate = modificationDate
                    }
                    if let participantIDs = record["participants"] as? [String] {
                        self.fetchParticipants(UIDs: participantIDs) { users in
                            // Now 'users' contains the fetched User objects for the participant IDs
                            let activity = Activity(recordID: recordID, from: record["startDate"] as? Date ?? Date(), to: record["endDate"] as? Date ?? Date(), name: record["name"] as? String ?? "No Name", participants: users)
                            self.activities.append(activity)
                        }
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
                    print("Fetched all Activity. No additional data to fetch.")
                }
            case .failure(let error):
                print("Query failed with error: \(error.localizedDescription)")
            }
        }
        UserDefaults.standard.set(mostRecentUpdate, forKey: "lastActivityFetchDate")
        CKContainer.default().publicCloudDatabase.add(operation)

    }
    
    func addActivity(name: String, startDate: Date, endDate: Date, participants: [User], completion: @escaping (Result<Activity, Error>) -> Void) {
        guard let uid = UserDefaults.standard.value(forKey: "uid") as? String else { return }
        let newActivity = CKRecord(recordType: "ActivityData")
        var participantsUID = convertUserToUID(Users: participants)
        
        participantsUID.append(uid)
        newActivity["name"] = name
        newActivity["startDate"] = startDate
        newActivity["endDate"] = endDate
        newActivity["participants"] = participantsUID
        
        CKContainer.default().publicCloudDatabase.save(newActivity) { (record, error) in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else  if let record = record{
                    let activity = Activity(recordID: record.recordID, from: startDate, to: endDate, name: name, participants: participants)
                    completion(.success((activity)))
                }
            }
        }
    }
    
    func convertUserToUID(Users: [User]) -> [String] {
        var result: [String] = []
        for user in Users {
            result.append(user.uid)
        }
        return result
    }
    
    func removeActivity(recordID: CKRecord.ID, completion: @escaping (Result<Void, Error>) -> Void){
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
    
    func fetchParticipants(UIDs: [String], completion: @escaping ([User]) -> Void) {
        var users = [User]()
            
        // Predicate to find users with UIDs in the participantUIDs array
        let predicate = NSPredicate(format: "uid IN %@", UIDs)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                // Successfully fetched a record, map it to a User
                if let name = record["name"] as? String, let uid = record["uid"] as? String {
                    let user = User(recordID: recordID, name: name, uid: uid)
                    users.append(user)
                }
            case .failure(let error):
                print("Failed to fetch record with ID \(recordID): \(error)")
            }
        }
        
        operation.queryResultBlock = { result in
            switch result {
            case .success(_):
                // Completed fetching all records
                DispatchQueue.main.async {
                    completion(users)
                }
            case .failure(let error):
                print("Failed to fetch participants: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
        CKContainer.default().publicCloudDatabase.add(operation)
    }
}

extension ActivitiesViewModel {
    static func withSampleData() -> ActivitiesViewModel {
        let sampleViewModel = ActivitiesViewModel()
        // Add a sample activity to your view model
        sampleViewModel.activities.append(Activity(recordID: CKRecord(recordType: "ActivityData").recordID, from: Date(), to: Date(), name: "Name", participants: []))
        
        return sampleViewModel
    }
}
