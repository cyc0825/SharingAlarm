//
//  FriendsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI
import TipKit

struct FriendsView: View {
    @EnvironmentObject var viewModel: FriendsViewModel
    @State private var showingAddFriend = false
    @State private var hasNewFriendRequests = false
    @State private var showDeleteConfirmation = false
    @State private var showFriendsCompare = false
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedFriend = viewModel.friends[index]
                                showFriendsCompare = true
                            }
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
                    .popoverTip(FriendsTip())
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
            }
            .sheet(isPresented: $showFriendsCompare, content: {
                if let selectedFriend = viewModel.selectedFriend {
                    FriendsCompareView(selectedFriend: selectedFriend)
                }
            })
        }
    }
}

struct FriendsCompareView: View {
    @State var userName: String = UserDefaults.standard.value(forKey: "name") as? String ?? ""
    
    var selectedFriend: FriendReference
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Image(uiImage: AvatarGenerator.generateAvatar(for: selectedFriend.friendRef.name, size: CGSize(width: 100, height: 100)) ?? UIImage())
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)
                Image(systemName: "hands.and.sparkles.fill")
                    .padding(30)
                Image(uiImage: AvatarGenerator.generateAvatar(for: userName, size: CGSize(width: 100, height: 100)) ?? UIImage())
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)
            }
            .padding()
            Text("You have became friends since \(selectedFriend.timestamp.formatted(date: .long, time: .omitted))")
        }
        .onAppear {
            print("Present Friend Compare")
        }
        .presentationDetents([.fraction(0.3)])
    }
}
