//
//  AddFriendCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/7.
//

import SwiftUI

struct AddFriendCard: View {
    var friend: User
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
                viewModel.sendFriendRequest(to: friend.uid) { result in
                    switch result {
                    case .success():
                        print("Friend requested successfully.")
                    case .failure(let error):
                        print("Failed to request friend: \(error.localizedDescription)")
                    }}
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

