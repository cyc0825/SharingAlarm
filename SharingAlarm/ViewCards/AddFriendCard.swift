//
//  AddFriendCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/7.
//

import SwiftUI
import FirebaseAuth

struct AddFriendCard: View {
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
            Button(action: {
                // Trigger the friend request action
                print("FR sent to \(friend.id!)")
                viewModel.saveFriendRequest(user2ID: friend.id!)
                requestSent = true
            }) {
                Text("Request")
            }
            .disabled(requestSent)
        }
    }
    
    private func sendRequest() {
            requestSent = true
        }
}

