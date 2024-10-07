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
    @State var showQRCode: Bool = false
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
                    HStack {
                        Divider()
                            .rotationEffect(.degrees(90))
                            .frame(height: 20)
                        Text("or")
                            .padding(.horizontal)
                        Divider()
                            .rotationEffect(.degrees(90))
                            .frame(height: 20)
                    }
                    Button {
                        showQRCode = true
                    } label: {
                        Text("Show your QR code")
                    }
                    .buttonStyle(.borderedProminent)
                    
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
                    viewModel.fetchOwnRequest()
                }
                .navigationBarTitle("Add Friends", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showQRCode) {
                    QRCodeView()
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    AddFriendView(viewModel: FriendsViewModel())
}
