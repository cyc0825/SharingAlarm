//
//  MembershipView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/11.
//

import SwiftUI
import StoreKit

struct PremiumStoreView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    var body: some View {
        if #available(iOS 17.0, *) {
            SubscriptionStoreView(groupID: "21542755"){
                StoreContentView()
            }
            .subscriptionStoreButtonLabel(.multiline)
            .onDisappear {
                userViewModel.fetchUserData { success in
                    if success {
                        print("fetch user data success")
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            Text("You need to upgrade to iOS 17 to use this feature.")
        }
    }
    
}

struct StoreContentView: View {
    @State private var currentIndex: Int = 0
    let features: [PremiumFeature] = [
        PremiumFeature(title: "Unlimited Alarms", description: "Schedule unlimited alarms to keep your day fully organized without limits.", imageName: "premium_infinite"),
        PremiumFeature(title: "Customized Ringtone", description: "Create and use your own customized ringtones for yourself or your groups.", imageName: "premium_customized"),
        PremiumFeature(title: "Premium Icon", description: "Unlock exclusive premium icons to represent your profile.", imageName: "premium_icon"),
        PremiumFeature(title: "Earn Premium Badge", description: "Earn a premium badge to show your commitment to premium features.", imageName: "premium_badge")
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentIndex) {
                ForEach(features.indices, id: \.self) { index in
                    PremiumFeatureView(feature: features[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        }
        .onAppear {
            currentIndex = 0 // Initialize currentIndex when the view appears
        }
    }
}

struct PremiumFeatureView: View {
    let feature: PremiumFeature
    let gradientSurface = LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
    let gradientBorder = LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.0), .white.opacity(0.0), .green.opacity(0.0), .green.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    var body: some View {
        ZStack {
            Image(feature.imageName)
                .resizable()
                .scaledToFill()
            VStack {
                Spacer()
                VStack {
                    Text(feature.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    Text(feature.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding([.horizontal, .bottom], 10)
                }
                .background(.ultraThinMaterial)
                .mask( RoundedRectangle(cornerRadius: 15, style: .circular).foregroundColor(.black))
                .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 8)
                .padding()
                .padding(.bottom)
            }
        }
    }
}

struct PremiumFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

struct StoreContentView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumStoreView()
    }
}
