
import SwiftUI
import AVFoundation

struct UIPlayView: View {
    
    @State private var selection = 0
    @State var phoneNumber = ""
    @State private var codeDigits = Array(repeating: "", count: 6)
    
    var body: some View {
        TabView(selection: $selection) {
            // Phone Number Input Page
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "phone")
                    Text("+1")
                    TextField("(XXX) XXX-XXXX", text: $phoneNumber)
                        .onChange(of: phoneNumber) { newValue in
                            let formattedNumber = newValue.formatPhoneNumber()
                            if formattedNumber != newValue {
                                phoneNumber = formattedNumber
                            }
                        }
                        .accentColor(.thirdAccent)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.numberPad)
                }
                .padding()
                .background(Capsule()
                    .fill(.secondAccent.opacity(0.4)))
                
                Button {
                    withAnimation {
                        selection = 1 // Move to the SMS code input page
                    }
                } label: {
                    Text("Send")
                        .foregroundStyle(.systemText)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Capsule().fill(.secondAccent))
            }
            .tag(0) // Tag for the first tab (Phone Number Page)
            .gesture(DragGesture())
            
            // SMS Code Input Page
            VStack {
                HStack(spacing: 10) {
                    ForEach(0..<6) { index in
                        TextField("", text: $codeDigits[index])
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(.secondAccent.opacity(0.5)))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                    }
                }
                .contentShape(Rectangle()) // Make the entire HStack tappable
                .padding(.bottom)
                
                Button {
                    withAnimation {
                        selection = 0 // Move to the SMS code input page
                    } // Function to handle sign-in
                } label: {
                    Text("Verify")
                        .foregroundStyle(.systemText)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Capsule().fill(.secondAccent))
            }
            .tag(1) // Tag for the second tab (SMS Code Input Page)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}

#Preview {
    UIPlayView()
}
