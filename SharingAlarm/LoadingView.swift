//
//  LoadingView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/5.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.lightGray).opacity(0.4).edgesIgnoringSafeArea(.all)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accent))
                .scaleEffect(1.5) // Makes the spinner larger
        }
    }
}

#Preview {
    LoadingView()
}
