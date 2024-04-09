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
                Text(viewModel.friendRequests[index].senderName)
                    .font(.headline)
                    .bold()
                Text(viewModel.friendRequests[index].senderID)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            Spacer()
            Divider()
                .padding(.vertical)
            VStack {
                Button(action: {
                    withAnimation {
                        animatePop = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            animatePop = false
                            viewModel.removeFriendRequest(viewModel.friendRequests[index]) { result in
                                switch result {
                                case .success():
                                    print("Request removed successfully.")
                                    viewModel.addFriendship(fromRequest: viewModel.friendRequests[index], receiverID: UserDefaults.standard.value(forKey: "uid") as! String) { result in
                                        switch result {
                                        case .success():
                                            print("Friendship added successfully.")
                                            viewModel.friendRequests.remove(at: index)
                                        case .failure(let error):
                                            print("Failed to add friendship: \(error.localizedDescription)")
                                        }
                                    }
                                case .failure(let error):
                                    print("Failed to remove request: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }) {
                    Text("Accept")
                        .foregroundColor(.white)
                }
                Divider()
                Button(action: {
                    withAnimation {
                        animatePop = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Ensure this matches animation duration
                            animatePop = false
                            viewModel.removeFriendRequest(viewModel.friendRequests[index]) { result in
                                if case .failure(let error) = result {
                                    print("Failed to remove request: \(error.localizedDescription)")
                                } else {
                                    print("Request declined successfully.")
                                    viewModel.friendRequests.remove(at: index)
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
        .background(Color.gray)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
