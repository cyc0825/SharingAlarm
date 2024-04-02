//
//  FriendsViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import Foundation

struct Friend: Identifiable, Codable {
    var id = UUID()
    var name: String
}

class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    
    // Add a friend to the list
    func addFriend(name: String) {
        let newFriend = Friend(name: name)
        friends.append(newFriend)
        // Save friends to persistent storage if needed
    }
}
