import StoreKit
import SwiftUI


enum PremiumLevel {
    case basic
    case premium

}

struct Test: View {
    
    var body: some View {
        SubscriptionStoreView(groupID: "21542755"){
            Tests()
        }
        .subscriptionStoreButtonLabel(.multiline)
    }
    
}

struct Tests: View {
    var body: some View {
        HStack(alignment: .center) {
            Image("premium")
                .resizable()
                .scaledToFill()
        }
    }
}

#Preview {
    Test()
}
