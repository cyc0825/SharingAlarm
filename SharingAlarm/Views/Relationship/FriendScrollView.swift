//
//  FriendScrollView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/30.
//

import StoreKit
import SwiftUI

struct FriendScrollView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @State private var showDeleteConfirmation = false
    @State private var showFriendsCompare = false
    @State private var friendToDelete: AppUser?
    
    // Sorted and grouped friends
    var groupedFriends: [String: [FriendReference]] {
        Dictionary(grouping: viewModel.friends) { friend in
            let firstCharacter = String(friend.friendRef.name.prefix(1))
            
            if let firstLetter = firstCharacter.first, firstLetter.isLetter {
                if alphabet.contains(firstCharacter.uppercased()) {
                    return firstCharacter.uppercased()
                } else {
                    return "#"
                }
            } else {
                return "#"
            }
        }
        .mapValues { $0.sorted { $0.friendRef.name < $1.friendRef.name } } // Sort names within each section
    }
    
    // Alphabetical sections, including '#'
    let alphabet = ("ABCDEFGHIJKLMNOPQRSTUVWXYZ#").map { String($0) }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack(alignment: .trailing) {
                List {
                    ForEach(alphabet, id: \.self) { letter in
                        if let friendRefs = groupedFriends[letter] {
                            Section(header: Text(letter)) {
                                VStack(spacing: 4) {
                                    ForEach(friendRefs, id: \.self) { friend in
                                        UserCard(name: friend.friendRef.name, swipable: true, onTapAction: {
                                            viewModel.selectedFriend = friend
                                            showFriendsCompare = true
                                        }, onDeleteAction: {
                                            friendToDelete = friend.friendRef
                                            showDeleteConfirmation = true
                                        })
//                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
//                                            Button {
//                                                    friendToDelete = friend.friendRef
//                                                    showDeleteConfirmation = true
//                                                } label: {
//                                                    ZStack {
//                                                        Capsule()
//                                                            .fill(Color.red) // Capsule-shaped background
//                                                            .frame(width: 80, height: 40)
//                                                            .cornerRadius(10)
//                                                        
//                                                        Label("Delete", systemImage: "trash")
//                                                            .foregroundColor(.white)  // Button text color
//                                                    }
//                                                }
//                                        }
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color(UIColor.systemGroupedBackground))
                            .id(letter) // Section identifier for scrolling
                        }
                    }
                }
                .listStyle(.plain)
                .padding(.trailing, 40) // Provide space for the alphabet index
                
                // Alphabetical index on the right with drag functionality
                VStack {
                    AlphabetIndexView(alphabet: alphabet) { selectedLetter in
                        withAnimation {
                            scrollProxy.scrollTo(selectedLetter, anchor: .top) // Scroll to section
                        }
                    }
                }
                .frame(width: 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .confirmationDialog("Are you sure you want to delete this friend?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let friendToDelete = friendToDelete {
                        viewModel.removeFriend(for: friendToDelete)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let friendToDelete = friendToDelete {
                    Text("Would you like to remove \(friendToDelete.name) from your friends list?")
                }
            }
            .sheet(isPresented: $showFriendsCompare, content: {
                if let selectedFriend = viewModel.selectedFriend {
                    FriendsCompareView(selectedFriend: selectedFriend)
                }
            })
        }
    }
}

// Alphabetical Index View
struct AlphabetIndexView: View {
    let alphabet: [String]
    var onSelectedLetter: (String) -> Void
    
    @State private var draggingLetter: String?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach(alphabet, id: \.self) { letter in
                    Text(letter)
                        .font(.caption)
                        .foregroundStyle(Color.accent)
                        .frame(width: 20, height: 20)
                        .background(draggingLetter == letter ? Color.thirdAccent : Color.clear)
                        .cornerRadius(5)
                        .onTapGesture {
                            onSelectedLetter(letter)
                        }
                }
            }
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let yPosition = value.location.y
                    let alphabetHeight = 20
                    let index = min(max(Int(yPosition / CGFloat(alphabetHeight)), 0), alphabet.count - 1)
                    let letter = alphabet[index]
                    draggingLetter = letter
                    onSelectedLetter(letter)
                }
                .onEnded { _ in
                    draggingLetter = nil
                }
            )
        }
    }
}



#Preview {
    FriendScrollView(viewModel: FriendsViewModel())
}
