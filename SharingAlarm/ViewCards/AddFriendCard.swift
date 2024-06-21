//
//  AddFriendCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/7.
//

import SwiftUI
import FirebaseAuth

struct AddFriendCard: View {
    let uid = UserDefaults.standard.value(forKey: "uid") as? String
    var friend: AppUser
    var viewModel: FriendsViewModel
    @State private var requestSent = false
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(friend.name)
                    .font(.headline)
                Text(friend.uid)
                    .font(.subheadline)
            }
            Spacer()
            if friend.uid == uid {
                Text("you")
            } else if !viewModel.friends.contains(where: { $0.friendRef.uid == friend.uid }) {
                Button(action: {
                    // Trigger the friend request action
                    print("FR sent to \(friend.id!)")
                    viewModel.saveFriendRequest(user2ID: friend.id!)
                    requestSent = true
                }) {
                    isRequestDisabled() ? Text("Requested") : Text("Request")
                }
                .disabled(isRequestDisabled())
            }
        }
    }
    
    @MainActor
    private func isRequestDisabled() -> Bool {
        friend.uid == uid || requestSent || viewModel.ownRequests.contains(where: { $0.friendRef.uid == friend.uid })
    }
}

