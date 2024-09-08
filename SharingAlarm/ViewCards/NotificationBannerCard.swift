//
//  NotificationBannerCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/6.
//

import SwiftUI

struct NotificationBannerCard: View {
    var name = UserDefaults.standard.string(forKey: "name") ?? "SharingAlarm"
    @Binding var alarmBody: String
    @Binding var alarmTime: Date
    
    var body: some View {
        ZStack {
            // Background theme image
            Image("iOS18ThemeBackground") // Add your theme image to Assets and replace this name
                .resizable()
                .frame(height: 120)
                .edgesIgnoringSafeArea(.all)
                .cornerRadius(10)
            VStack {
                HStack {
                    Image("icon") // Placeholder for the app icon
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("SharingAlarm")
                                .font(.headline)
                            Spacer()
                            Text(alarmTime.formatted(date: .omitted, time: .shortened))
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        
                        Text("\(name) wants you to \(alarmBody)")
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    .padding(.leading, 4)
                    
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.9))
                .cornerRadius(10)
                .shadow(radius: 2)
            }
            .padding(.horizontal, 5)
        }
    }
}

struct NotificationBannerCard_Previews: PreviewProvider {
    @State static var alarmBody = "wake up!"
    @State static var alarmTime: Date = Date()

    static var previews: some View {
        NotificationBannerCard(
            alarmBody: $alarmBody,
            alarmTime: $alarmTime
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
