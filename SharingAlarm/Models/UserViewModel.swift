//
//  UserData.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import Foundation
import SwiftUI
import Combine
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

enum AuthMethod {
    case apple
    case google
    // Add more as needed
}

@MainActor
class UserViewModel: ObservableObject {
    @Published var appUser = AppUser.empty

    @Published private var user: User?
    private var db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    init() {
      registerAuthStateHandler()

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
                self.fetchUserData()
            }
        }
    }
    
    func fetchUserData() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        Task {
            debugPrint("[fetchUserData] starts for \(userID)")
            do {
                self.appUser = try await db.collection("UserData").document(userID).getDocument(as: AppUser.self)
                UserDefaults.standard.setValue(self.appUser.name, forKey: "name")
                UserDefaults.standard.setValue(self.appUser.uid, forKey: "uid")
            }
            catch {
                debugPrint("[fetchUserData] fails")
                print(error.localizedDescription)
            }
            debugPrint("[fetchUserData] ends with \(self.appUser)")
        }
    }
    
    func saveUserData() {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        
        do {
            try db.collection("UserData").document(userID).setData(from: appUser)
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func updateUserData(updates: [String: String]) {
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
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
}
