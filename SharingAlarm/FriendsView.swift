//
//  FriendsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI
import CloudKit

struct FriendsView: View {
    @StateObject var viewModel = FriendsViewModel()
    @State private var showingAddFriend = false
    @State private var hasNewFriendRequests = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.friends.isEmpty {
                    Text("Tap the add button and add your friends.")
                        .padding()
                } else {
                    List(viewModel.friends, id: \.recordID) { friend in
                        Text(friend.name)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.removeFriendship(recordID: friend.recordID) { result in
                                        switch result {
                                        case .success():
                                            print("Request removed successfully.")
                                        case .failure(let error):
                                            print("Failed to remove friend: \(error.localizedDescription)")
                                        }
                                    }       
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .onAppear{
                viewModel.searchRequest()
                viewModel.fetchFriends()
            }
            .navigationTitle("Friends")
            .navigationBarItems(trailing: Button(action: {
                showingAddFriend = true
            }) {
                if viewModel.friendRequests.count > 0 {
                    Image(systemName: "plus.circle")
                } else {
                    Image(systemName: "plus")
                }
            })
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
            .navigationBarTitle("Add Friends", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview{
    AddFriendView(viewModel: FriendsViewModel())
}
