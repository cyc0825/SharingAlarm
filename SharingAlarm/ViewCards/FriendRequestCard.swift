//
//  FriendRequestCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/8.
//

import SwiftUI

struct FriendRequestCard: View {
    var viewModel: FriendsViewModel
    var index: Int
    @State private var animatePop = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.friendRequests[index].friendRef.name)
                    .font(.headline)
                    .bold()
                Text(viewModel.friendRequests[index].friendRef.uid)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            Spacer()
            Divider()
                .padding(.vertical)
            VStack {
                Button(action: {
                    withAnimation {
                        // Remove the item immediately to stop rendering the card
                        let friendRequest = viewModel.friendRequests[index]
                        viewModel.friendRequests.remove(at: index)

                        // Continue with your async work after the view updates
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            Task {
                                let success = try await viewModel.removeFriendRequest(fromRequest: friendRequest)
                                if success {
                                    viewModel.saveFriendShip(fromRequest: friendRequest)
                                }
                            }
                        }
                    }
                }) {
                    Text("Accept")
                }
                Divider()
                Button(action: {
                    withAnimation {
                        // Remove the item immediately to stop rendering the card
                        let friendRequest = viewModel.friendRequests[index]
                        viewModel.friendRequests.remove(at: index)

                        // Continue with your async work after the view updates
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            Task {
                                let success = try await viewModel.removeFriendRequest(fromRequest: friendRequest)
                                if success {
                                    // Handle further logic if needed
                                }
                            }
                        }
                    }
                }) {
                    Text("Decline")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 100)
        }

        .scaleEffect(animatePop ? 1.1 : 1.0) // Slightly enlarge the card when animatePop is true
        .animation(.easeInOut(duration: 0.2), value: animatePop)
        .padding()
        .frame(width: UIScreen.main.bounds.width * 5 / 6, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}
