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
        VStack{
            Spacer()
            NavigationView {
                VStack {
                    TextField("Search by name or UID", text: $searchQuery, onCommit: {
                        viewModel.fetchFriendSearch(query: searchQuery)
                    })
                    .submitLabel(.search)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    
                    List(viewModel.friendSearchResults, id: \.id) { friend in
                        AddFriendCard(friend: friend, viewModel: viewModel)
                    }
                    if !viewModel.friendRequests.isEmpty {
                        TabView {
                            ForEach(viewModel.friendRequests.indices, id: \.self) { index in
                                FriendRequestCard(viewModel: viewModel, index: index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: UIScreen.main.bounds.height / 10)
                    }
                }
                .onDisappear {
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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
