//
//  GroupCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/11.
//

import SwiftUI
import CloudKit

struct GroupCard: View {
    @StateObject var viewModel: GroupsViewModel
    var group: Groups
    var body: some View {
        ZStack {
            VStack {
                Text(group.name)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("\(group.alarmCount) Alarm(s)")
                        .font(.footnote)
                    Divider()
                    Text("\(group.participants.count) Pariticpant(s)")
                        .font(.footnote)
                    Divider()
                    Text(group.to.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: UIScreen.main.bounds.width * 4 / 5, height: 60)
        .cornerRadius(10)
        
    }
}

//struct GroupCard_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleViewModel = GroupsViewModel.withSampleData()
//        GroupCard(viewModel: sampleViewModel, index: 0)
//            .previewLayout(.sizeThatFits) // Adjust the layout as needed
//    }
//}
