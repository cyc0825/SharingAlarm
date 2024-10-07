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

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.friends.isEmpty {
                    List {
                        Text("Tap the add button and add your friends.")
                            .padding()
                    }
                }
                else {
                    FriendScrollView(viewModel: viewModel)
                }
            }
            .navigationTitle("Friends")
            .refreshable {
                viewModel.fetchFriends()
                viewModel.fetchOwnRequest()
                viewModel.fetchFriendsRequest()
            }
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 17.0, *) {
                        Button(action: {
                            showingAddFriend = true
                        }) {
                            if viewModel.friendRequests.count > 0 {
                                Image(systemName: "person.fill.badge.plus")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.red, Color.accent)
                            } else {
                                Image(systemName: "person.fill.badge.plus")
                                    .foregroundStyle(Color.accent)
                            }
                        }
                        .popoverTip(FriendsTip())
                    } else {
                        // Fallback on earlier versions
                        Button(action: {
                            showingAddFriend = true
                        }) {
                            if viewModel.friendRequests.count > 0 {
                                Image(systemName: "person.fill.badge.plus")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.red, Color.accent)
                            } else {
                                Image(systemName: "person.fill.badge.plus")
                                    .foregroundStyle(Color.accent)
                            }
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
