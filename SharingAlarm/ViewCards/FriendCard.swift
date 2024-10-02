//
//  FriendCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/10/2.
//

import SwiftUI

struct FriendCard: View {
    var name: String
    var body: some View {
        HStack {
            Image(uiImage: AvatarGenerator.generateAvatar(for: name, size: CGSize(width: 30, height: 30)) ?? UIImage())
            Text(name)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Capsule().fill(.ultraThinMaterial))
    }
}


struct FriendCard_Previews: PreviewProvider {
    static var previews: some View {
        FriendCard(name: "Previews")
    }
}
