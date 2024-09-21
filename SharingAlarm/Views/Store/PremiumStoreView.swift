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
    }
    
}

struct StoreContentView: View {
    var body: some View {
        HStack(alignment: .center) {
            Image("premium")
                .resizable()
                .scaledToFill()
        }
    }
}

#Preview {
    PremiumStoreView()
}
