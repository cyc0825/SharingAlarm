
import SwiftUI

struct CustomSwipeRow: View {
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false

    var body: some View {
        ZStack {
            // Background Delete Button (Initially hidden, shows on swipe)
            HStack {
                Spacer()
                Button(action: {
                    print("Delete action triggered")
                }) {
                    Image(systemName: "trash")
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                        .padding(10)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.red))
                }
                .padding(.trailing, 15)
            }

            // Main Row Content
            UserCard(name: "cyc", swipable: true)
        }
        .frame(height: 60)
        .padding(.horizontal)
        .contentShape(Rectangle()) // Ensures the entire row is tappable
    }
}
struct UIPlayView: View {
    var body: some View {
        ForEach(1...10, id: \.self) { _ in
            CustomSwipeRow()
        }
    }
}
#Preview {
    UIPlayView()
}
