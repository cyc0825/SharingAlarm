//
//  StyleView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/5.
//
import SwiftUI

struct FloatingFriendRequestsView: View {
    var body: some View {
        VStack {
            // Your friend requests content here
        }
        .frame(height: UIScreen.main.bounds.height / 5)
        .background(BlurView(style: .systemMaterial))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding()
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct LargeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(Color.secondary)
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

struct DropdownMenu: View {
    @Binding var isExpanded: Bool
    @Binding var selectedOption: String
    let options: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(selectedOption.isEmpty ? "Select an option" : selectedOption)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }

            if isExpanded {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        withAnimation {
                            isExpanded = false
                            selectedOption = option
                            onSelect(option)
                        }
                    }) {
                        Text(option)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}
