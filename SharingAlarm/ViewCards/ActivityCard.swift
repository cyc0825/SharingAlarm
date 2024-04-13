//
//  ActivityCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/11.
//

import SwiftUI

struct ActivityCard: View {
    var viewModel: ActivitiesViewModel
    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
                Text("ActivityName")
                Text("Next Alarm: ")
                HStack{
                    Rectangle()
                        .fill(.gray)
                        .frame(width:35, height:35)
                        .cornerRadius(10)
                }
                Spacer()
            }
        }
        .frame(width: UIScreen.main.bounds.width * 4 / 5, height: 100)
        .cornerRadius(10)
    }
}

#Preview {
    ActivityCard(viewModel: ActivitiesViewModel())
}
