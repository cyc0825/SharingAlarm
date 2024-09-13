//
//  EconomyViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/10.
//

import Foundation
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
