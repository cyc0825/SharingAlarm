//
//  UserData.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import Foundation
import SwiftUI
import Combine

import FirebaseMessaging
import FirebaseAuth
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var uid: String
    
    static var empty: AppUser {
        AppUser(name: "", uid: "")
    }
}

struct UserReference: Codable, Identifiable {
    @DocumentID var id: String?
    var userRef: AppUser
}

enum AuthMethod {
    case apple
    case google
    // Add more as needed
}

@MainActor
class UserViewModel: ObservableObject {
    @Published var appUser = AppUser.empty
    
    @Published var user: User?
    
    static let shared = UserViewModel()
    
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        registerAuthStateHandler()
        if let userId = Auth.auth().currentUser?.uid {
            updateFCMTokenIfNeeded(userId: userId)
        }
        
        $user
            .compactMap { $0 }
            .sink { user in
                UserDefaults.standard.setValue(user.uid, forKey: "userID")
            }
            .store(in: &cancellables)
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                self.fetchUserData { _ in}
            }
        }
    }
    
    func updateFCMTokenIfNeeded(userId: String) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
                return
            }
            
            guard let token = token else {
                print("FCM token is nil")
                return
            }
            self.db.collection("UserData").document(userId).setData(["fcmToken": token], merge: true) { error in
                if let error = error {
                    print("Error updating FCM token: \(error)")
                } else {
                    print("FCM token updated successfully")
                }
            }
        }
    }
    
    func fetchUserData(completion: @escaping (Bool) -> Void) {
        guard let userID = user?.uid else {
            completion(false)
            return
        }

        Task {
            debugPrint("[fetchUserData] starts for \(userID)")
            do {
                let document = try await db.collection("UserData").document(userID).getDocument()
                if let appUser = try? document.data(as: AppUser.self) {
                    self.appUser = appUser
                    UserDefaults.standard.setValue(self.appUser.name, forKey: "name")
                    UserDefaults.standard.setValue(self.appUser.uid, forKey: "uid")
                    completion(true)
                } else {
                    debugPrint("[fetchUserData] no document found for \(userID)")
                    completion(false)
                }
            } catch {
                debugPrint("[fetchUserData] fails")
                print(error.localizedDescription)
                completion(false)
            }
            debugPrint("[fetchUserData] ends with \(String(describing: self.appUser))")
        }
    }
    
    func saveUserData() {
        guard let userID = user?.uid else { return }
        do {
            try db.collection("UserData").document(userID).setData(from: appUser)
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func updateUserData(updates: [String: String]) {
        guard let userID = user?.uid else { return }
        db.collection("UserData").document(userID).updateData(updates)
        for (key, value) in updates {
            switch key {
            case "name":
                appUser.name = value
                UserDefaults.standard.setValue(value, forKey: "name")
            case "uid":
                appUser.uid = value
                UserDefaults.standard.setValue(value, forKey: "uid")
            default:
                print("Unknown key \(key)")
            }
        }
    }
    
    func checkIfUIDExists(uid: String, completion: @escaping (Bool) -> Void) {
        print("Check \(uid) exist")
            db.collection("UserData").whereField("uid", isEqualTo: uid).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error checking UID: \(error)")
                    completion(false)
                } else if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
}
