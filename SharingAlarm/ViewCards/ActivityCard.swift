//
//  ActivityCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/11.
//

import SwiftUI
import CloudKit

struct ActivityCard: View {
    @StateObject var viewModel: ActivitiesViewModel
    var activity: Activity
    var body: some View {
        ZStack {
            VStack {
                Text(activity.name)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("\(activity.alarmCount) Alarm(s)")
                        .font(.footnote)
                    Divider()
                    Text("\(activity.participants.count) Pariticpant(s)")
                        .font(.footnote)
                    Divider()
                    Text(activity.to.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: UIScreen.main.bounds.width * 4 / 5, height: 60)
        .cornerRadius(10)
        
    }
}

//struct ActivityCard_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleViewModel = ActivitiesViewModel.withSampleData()
//        ActivityCard(viewModel: sampleViewModel, index: 0)
//            .previewLayout(.sizeThatFits) // Adjust the layout as needed
//    }
//}
