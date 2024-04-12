//
//  AuthViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/8.
//

import SwiftUI
import AuthenticationServices
import CloudKit
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userExists: Bool = false
    @Published var shouldShowProfileSetup: Bool = false
    @Published var user: AppUser?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        isAuthenticated = UserDefaults.standard.bool(forKey: "logged")
        $userExists
            .receive(on: DispatchQueue.main)
            .sink { [weak self] exists in
                self?.updateShowingProfileSetup()
            }
            .store(in: &cancellables)
    }
    
    func updateShowingProfileSetup() {
        // Adjust this logic as needed. This is a simple example.
        shouldShowProfileSetup = isAuthenticated && userExists == false
    }
    
    func updateAuthenticationState(isAuthenticated: Bool) {
        UserDefaults.standard.set(isAuthenticated, forKey: "logged")
        self.isAuthenticated = isAuthenticated
    }
    
    func fetchUserByAppleID(completion: @escaping (CKRecord?, Error?) -> Void) {
        
        guard let appleIDCredential = UserDefaults.standard.value(forKey: "appleIDUser") as? String else {
            completion(nil, nil) // No appleIDCredential stored
            return
        }
        let predicate = NSPredicate(format: "appleIDCredential == %@", appleIDCredential)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        let database = CKContainer.default().publicCloudDatabase
        
        database.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(records?.first, nil) // Assuming only one record per appleIDCredential
        }
    }
    
    // This function is for authorizing when the app is first logged in
    func checkUserExistsWithAppleID(appleID: String) {
        let predicate = NSPredicate(format: "appleIDCredential == %@", appleID)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        let database = CKContainer.default().publicCloudDatabase
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                guard let self = self, error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                if let record = records?.first {
                    self.userExists = true
                    
                    // Assuming 'name' and 'email' are the field names in your CloudKit record.
                    let name = record["name"] as? String ?? "Unknown"
                    let uid = record["uid"] as? String ?? "Unknown"
                    
                    // Saving to UserDefaults
                    UserDefaults.standard.set(name, forKey: "name")
                    UserDefaults.standard.set(uid, forKey: "uid")
                    
                } else {
                    self.userExists = false
                }
            }
        }
    }
    
    func saveOrUpdateUserProfile(username: String, uid: String, completion: @escaping () -> Void) {
        fetchUserByAppleID { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Fetch error: \(error.localizedDescription)")
                    completion()
                    return
                }
                
                if let existingRecord = record {
                    // Update the existing record
                    existingRecord["name"] = username
                    existingRecord["uid"] = uid
                    updateUserRecord(existingRecord, completion: completion)
                    self.user = AppUser(name: username, uid: uid, authMethod: .apple)
                } else {
                    // No existing record, create a new one
                    self.user = AppUser(name: username, uid: uid, authMethod: .apple)
                    saveUserProfileToCloudKit(username: username, uid: uid, completion: completion)
                }
            }
        }
    }
    
    func setUserExists(_ exists: Bool) {
        DispatchQueue.main.async {
            self.userExists = exists
        }
    }
}
