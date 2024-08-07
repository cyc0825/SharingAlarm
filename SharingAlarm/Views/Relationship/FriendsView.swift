//
//  FriendsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI
import CloudKit

struct FriendsView: View {
    @EnvironmentObject var viewModel: FriendsViewModel
    @State private var showingAddFriend = false
    @State private var hasNewFriendRequests = false
    @State private var showDeleteConfirmation = false
    @State private var friendIDToDelete: Int?
    @State private var friendToDelete: String?

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.friends.isEmpty {
                    List {
                        Text("Tap the add button and add your friends.")
                            .padding()
                    }
                }
                else {
                    List(viewModel.friends.indices, id: \.self) { index in
                        Text(viewModel.friends[index].friendRef.name)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    friendIDToDelete = index
                                    friendToDelete = viewModel.friends[friendIDToDelete!].friendRef.name
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                }
            }
            .navigationTitle("Friends")
            .refreshable {
                viewModel.fetchFriends()
                viewModel.fetchOwnRequest()
                viewModel.fetchFriendsRequest()
            }
            .confirmationDialog("Are you sure you want to delete this friend?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    guard let friendIDToDelete = friendIDToDelete else { return }
                    viewModel.removeFriend(for: friendIDToDelete)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let friendToDelete = friendToDelete {
                    Text("Would you like to remove \(friendToDelete) from your friends list?")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        if viewModel.friendRequests.count > 0 {
                            Image(systemName: "plus.circle")
                        } else {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
            }
        }
    }
}

#Preview{
    AddFriendView(viewModel: FriendsViewModel())
}
