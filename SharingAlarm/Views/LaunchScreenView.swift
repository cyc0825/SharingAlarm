//
//  LaunchScreenView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/26.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false

    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea(edges: .all)
            VStack{
                Text("WELCOME!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.top, .bottom], 50)
                Image("loginscreen")
                    .resizable()
                    .frame(width: 300, height: 300)
                    .padding(.bottom, 40)
                Text("Sharing Alarm")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .center))
                    .fontDesign(.serif)
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                Spacer()
            }
            .padding()
        }
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}
