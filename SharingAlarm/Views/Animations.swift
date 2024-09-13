//
//  Animations.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/12.
//

import SwiftUI

struct Sparkle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var scale: CGFloat
    var rotation: Double
    var duration: Double
    var color: Color
}

struct PartyPopperView: View {
    @State private var sparkles: [Sparkle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(sparkles) { sparkle in
                    Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundColor(sparkle.color)
                        .opacity(sparkle.opacity)
                        .scaleEffect(sparkle.scale)
                        .rotationEffect(.degrees(sparkle.rotation))
                        .position(x: sparkle.x, y: sparkle.y)
                        .animation(.easeOut(duration: sparkle.duration), value: sparkle.y)
                }
            }
            .onAppear {
                shootSparkles(in: geometry.size)
            }
        }
    }
    
    private func shootSparkles(in size: CGSize) {
        sparkles = []
        
        // Generate multiple sparkles
        for _ in 0..<30 {
            let xStart = size.width / 2
            let yStart = size.height
            
            let randomColor = Color(
                red: Double.random(in: 0.4...1.0),
                green: Double.random(in: 0.4...1.0),
                blue: Double.random(in: 0.4...1.0)
            )
            
            let sparkle = Sparkle(
                x: xStart,
                y: yStart,
                opacity: 1.0,
                scale: CGFloat.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...360),
                duration: Double.random(in: 0.8...1.2),
                color: randomColor
            )
            sparkles.append(sparkle)
        }
        
        // Animate sparkles with gravity effect
        for index in sparkles.indices {
            let gravity = Double.random(in: 100...300)
            let randomXOffset = CGFloat.random(in: -150...150)
            
            withAnimation {
                sparkles[index].x += randomXOffset
                sparkles[index].y -= gravity
                sparkles[index].opacity = 0.0
            }
        }
        
        // Clear sparkles after the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            sparkles = []
        }
    }
}

struct AnimationView: View {
    @State private var showPartyPopper = false
    
    var body: some View {
        ZStack {
            // Your main content goes here
            
            if showPartyPopper {
                PartyPopperView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .onAppear {
            // Example of triggering the popper
            showPartyPopper = true
            
            // Automatically hide the popper after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showPartyPopper = false
            }
        }
    }
}

#Preview {
    AnimationView()
}
