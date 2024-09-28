//
//  EconomyViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/10.
//

import Foundation
import StoreKit
import FirebaseFirestore

class EconomyViewModel: ObservableObject {
    static let shared = EconomyViewModel()
    func updateCoinsForResponse(alarm: Alarm, earnedCoins: Int, userID: String?) async throws {
        // Check if the alarm interval is more than 2 hours
        guard let userID = userID else { return }
        let userRef = Firestore.firestore().collection("UserData").document(userID)
        let userSnapshot = try await userRef.getDocument()
        
        if let userData = userSnapshot.data(), let currentCoins = userData["money"] as? Int {
            let updatedCoins = currentCoins + earnedCoins
            try await userRef.updateData(["money": updatedCoins])
            print("Coins updated: Earned \(earnedCoins) coins.")
        }
    }
    
    func unlockRingtone(userID: String, ringtoneID: String, cost: Int) async throws -> Bool {
        let db = Firestore.firestore()
        let userRef = db.collection("UserData").document(userID)
        
        let userSnapshot = try await userRef.getDocument()
        
        if let userData = userSnapshot.data(), let currentCoins = userData["money"] as? Int, currentCoins >= cost {
            var unlockedRingtones = userData["unlockedRingtones"] as? [String] ?? []
            
            // Check if ringtone is already unlocked
            if unlockedRingtones.contains(ringtoneID) {
                print("Ringtone already unlocked.")
                return false
            }
            
            // Deduct coins and update unlocked ringtones
            let updatedCoins = currentCoins - cost
            unlockedRingtones.append(ringtoneID)
            
            try await userRef.updateData([
                "money": updatedCoins,
                "unlockedRingtones": unlockedRingtones
            ])
            print("Ringtone unlocked. \(cost) coins deducted.")
            return true
        } else {
            print("Insufficient coins to unlock the ringtone.")
            return false
        }
    }
}

// StoreKit
extension EconomyViewModel {

    // A method to start listening to transaction updates
    func listenForTransactions() {
        Task {
            for await verificationResult in Transaction.updates {
                switch verificationResult {
                case .verified(let transaction):
                    // Handle the verified transaction
                    await updateSubscriptionToFirebase(transaction: transaction)
                    UserDefaults.standard.set(true, forKey: "isPremium")
                    // Mark the transaction as finished after processing
                    await transaction.finish()
                case .unverified(_, let error):
                    // Handle the error if the transaction is not verified
                    print("Transaction not verified: \(error.localizedDescription)")
                }
            }
        }
    }

    // Method to update subscription information to Firebase
    func updateSubscriptionToFirebase(transaction: StoreKit.Transaction) async {
        // Get the subscription status (e.g., productID, expiration date, etc.)
        let productID = transaction.productID
        let expirationDate = transaction.expirationDate
        print("Product ID: \(productID)")
        print("Expiration Date: \(expirationDate?.description ?? "N/A")")
        let userID = UserDefaults.standard.string(forKey: "userID") ?? ""
        let data = ["subscription": productID, "expirationDate": expirationDate ?? Date()] as [String : Any]
        
        // Write the data to Firebase
        let db = Firestore.firestore()
        db.collection("UserData").document(userID).updateData(data) { error in
            if let error = error {
                print("Error updating subscription: \(error)")
            } else {
                print("Subscription updated successfully.")
            }
        }
    }
}

// icon Economy
extension EconomyViewModel {
    func unlockIcon(iconID: String) async throws -> Bool {
        var userID = UserDefaults.standard.string(forKey: "userID") ?? ""
        let db = Firestore.firestore()
        let userRef = db.collection("UserData").document(userID)
        
        let userSnapshot = try await userRef.getDocument()
        
        if let userData = userSnapshot.data(){
            var unlockedIcons = userData["unlockedIcons"] as? [String] ?? []
            
            // Check if ringtone is already unlocked
            if unlockedIcons.contains(iconID) {
                print("Icon already unlocked.")
                return false
            }
            
            // Deduct coins and update unlocked ringtones
            unlockedIcons.append(iconID)
            
            try await userRef.updateData([
                "unlockedIcons": unlockedIcons
            ])
            print("Icon unlocked")
            return true
        } else {
            print("Failed to unlock icon.")
            return false
        }
    }
}
