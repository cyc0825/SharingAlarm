//
//  GroupCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/11.
//

import SwiftUI

struct GroupCard: View {
    @StateObject var viewModel: GroupsViewModel
    @StateObject var alarmsViewModel: AlarmsViewModel
    var group: Groups
    var alarmsForGroup: [Alarm]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(group.name)
                        .font(.title2)
                        .bold()
                    AvatarStack(participants: group.participants)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                
                HStack {
                    Text(group.to.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Divider()
                    Text("\(alarmsForGroup.count) \(alarmsForGroup.count == 1 ? "Alarm" : "Alarms")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            if let firstAlarm = alarmsForGroup.first {
                PathView(alarm: firstAlarm, radius: 25, lineWidth: 12)
            }
        }
        .padding()  // Add padding inside the card
        .background(Capsule().fill(Color.listCellBackground))
        .frame(height: 100)
    }
}

struct AvatarStack: View {
    var participants: [AppUser]
    var body: some View {
        ZStack {
            ForEach(participants.prefix(3).indices, id: \.self) { index in
                Image(uiImage: AvatarGenerator.generateAvatar(for: participants[index].name, size: CGSize(width: 30, height: 30)) ?? UIImage())
                    .overlay(Circle().stroke(Color.listCellBackground, lineWidth: 2))
                    .offset(CGSize(width: 22 * Double(index), height: 0))
            }
            if participants.count - 3 > 0 {
                Image(uiImage: AvatarGenerator.generateAvatar(for: "\(participants.count - 3) +", size: CGSize(width: 30, height: 30)) ?? UIImage())
                    .overlay(Circle().stroke(Color.listCellBackground, lineWidth: 2))
                    .offset(CGSize(width: 22 * 3, height: 0))
            }
        }
    }
}

struct GroupCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleViewModel = GroupsViewModel.withSampleData()
        let group = Groups(from: Date(), to: Date(), name: "Test", participants: [])
        GroupCard(viewModel: sampleViewModel, alarmsViewModel: AlarmsViewModel(), group: group, alarmsForGroup: [Alarm(time: Date() + 100, sound: "", alarmBody: "test", repeatInterval: "")])
            .previewLayout(.sizeThatFits) // Adjust the layout as needed
    }
}
