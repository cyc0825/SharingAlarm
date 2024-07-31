//
//  AddFriendView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/7/28.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: FriendsViewModel
    @State private var name = ""

    @State private var searchQuery = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by name or UID", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Search") {
                    viewModel.fetchFriendSearch(query: searchQuery)
                }
                .padding()
                
                List(viewModel.friendSearchResults, id: \.id) { friend in
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
            .onDisappear {
                viewModel.fetchFriendsRequest()
                viewModel.fetchFriends()
                viewModel.fetchOwnRequest()
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
