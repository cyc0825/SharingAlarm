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
                Text(viewModel.friendRequests[index].friendRef.name)
                    .font(.headline)
                    .bold()
                Text(viewModel.friendRequests[index].friendRef.uid)
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
                            viewModel.saveFriendShip(fromRequest: viewModel.friendRequests[index])
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
                            viewModel.removeFriendRequest(fromRequest: viewModel.friendRequests[index])
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
