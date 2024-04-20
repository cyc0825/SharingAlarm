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
                    Text("Tap the add button and add your friends.")
                        .padding()
                } else {
                    List(viewModel.friends.indices, id: \.self) { index in
                        Text(viewModel.friends[index].name)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    friendIDToDelete = index
                                    friendToDelete = viewModel.friends[friendIDToDelete!].name
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                    .confirmationDialog("Are you sure you want to delete this friend?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            guard let friendIDToDelete = friendIDToDelete else { return }
                            viewModel.removeFriendship(recordID: viewModel.friends[friendIDToDelete].recordID) { result in
                                switch result {
                                case .success():
                                    viewModel.friends.remove(at: friendIDToDelete)
                                case .failure(let error):
                                    print("Failed to remove friend: \(error.localizedDescription)")
                                }
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        if let friendIDToDelete = friendIDToDelete {
                            Text("Would you like to remove \(friendToDelete!) from your friends list?")
                        }
                    }
                }
            }
            .refreshable {
                viewModel.fetchFriends()
                viewModel.searchRequest()
            }
            .navigationTitle("Friends")
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

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: FriendsViewModel
    @State private var name = ""

    @State private var searchQuery = ""
    @State private var searchResults: [CKRecord] = []
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by name or UID", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Search") {
                    viewModel.searchFriends(query: searchQuery)
                }
                .padding()
                
                List(viewModel.friendSearchResults, id: \.recordID) { friend in
                    AddFriendCard(friend: friend, viewModel: viewModel)
                }
                
                TabView {
                    ForEach(viewModel.friendRequests.indices, id: \.self) { index in
                        FriendRequestCard(viewModel: viewModel, index: index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: UIScreen.main.bounds.height / 10)
            }
            .onAppear{
                viewModel.searchRequest()
            }
            .onDisappear{
                viewModel.fetchFriends()
            }
            .navigationBarTitle("Add Friends", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview{
    AddFriendView(viewModel: FriendsViewModel())
}
