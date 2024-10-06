//
//  WelcomeView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/10/4.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        Text("Welcome to SharingAlarm")
        Button {
            
        } label: {
            Text("Let's Go")
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    WelcomeView()
}
