//
//  EconomyViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/10.
//

import Foundation
import FirebaseFirestore

class EconomyViewModel: ObservableObject {
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
    
    func unlockRingtone(userID: String, ringtoneID: String, cost: Int) async throws {
        let userRef = Firestore.firestore().collection("UserData").document(userID)
        let userSnapshot = try await userRef.getDocument()
        
        if let userData = userSnapshot.data(), let currentCoins = userData["money"] as? Int, currentCoins >= cost {
            let updatedCoins = currentCoins - cost
            try await userRef.updateData(["money": updatedCoins])
            print("Ringtone unlocked. \(cost) coins deducted.")
        } else {
            print("Insufficient coins to unlock the ringtone.")
        }
    }
}
