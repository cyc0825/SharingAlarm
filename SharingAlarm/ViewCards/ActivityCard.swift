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
            Text("ActivityCard")
        }
        .frame(width: UIScreen.main.bounds.width * 4 / 5, height: 100)
    }
}
