//
//  UserCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/10/3.
//

import SwiftUI

struct UserCard: View {
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = true
    var name: String
    var swipable = false
    var onTapAction: (() -> Void)?
    var onDeleteAction: (() -> Void)?
    var body: some View {
        ZStack {
            // Background Delete Button (Initially hidden, shows on swipe)
            HStack {
                Spacer()
                Button(action: {
                    onDeleteAction?()
                }) {
                    Image(systemName: "trash")
                        .frame(width: 24, height: 24)
                        .foregroundColor(.system)
                        .padding(10)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(Color.red))
                }
            }

            // Main Row Content
            if swipable {
                HStack {
                    Image(uiImage: AvatarGenerator.generateAvatar(for: name, size: CGSize(width: 30, height: 30)) ?? UIImage())
                    Text(name)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .frame(height: 50)
                .background(Capsule().fill(Color.listCellBackground))
                .offset(x: offset)
                .onTapGesture {
                    onTapAction?()
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 { // Swipe left only
                                self.offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            withAnimation {
                                if -value.translation.width > 70 {
                                    self.isSwiped = true
                                    self.offset = -70 // Adjust to how far you want the content to slide
                                } else {
                                    self.isSwiped = false
                                    self.offset = 0
                                }
                            }
                        }
                )
            } else {
                HStack {
                    Image(uiImage: AvatarGenerator.generateAvatar(for: name, size: CGSize(width: 30, height: 30)) ?? UIImage())
                    Text(name)
                }
                .onTapGesture {
                    onTapAction?()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .frame(height: 50)
                .background(Capsule().fill(Color.listCellBackground))
            }
        }
        .frame(height: 50)
        .contentShape(Rectangle())
    }
}

#Preview {
    UserCard(name: "Cao")
}
