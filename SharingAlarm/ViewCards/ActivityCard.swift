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
    var index: Int
    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea(edges: .all)
            VStack {
                Text(viewModel.activities[index].name)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    .padding(.top)
                HStack {
                    Text(viewModel.activities[index].from.formatted(date: .abbreviated, time: .omitted))
                    Divider()
                        .rotationEffect(.degrees(90))
                        .padding(.horizontal)
                    Text(viewModel.activities[index].to.formatted(date: .abbreviated, time: .omitted))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                Spacer()
            }
        }
        .frame(width: UIScreen.main.bounds.width * 4 / 5, height: 80)
        .cornerRadius(10)
        
    }
}

struct ActivityCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleViewModel = ActivitiesViewModel.withSampleData()
        ActivityCard(viewModel: sampleViewModel, index: 0)
            .previewLayout(.sizeThatFits) // Adjust the layout as needed
    }
}
