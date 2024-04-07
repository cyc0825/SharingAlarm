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

