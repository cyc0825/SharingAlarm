//
//  AlarmAnimation.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/12.
//

import SwiftUI

struct AlarmInterfaceView: View {
    @StateObject var viewModel = AlarmsViewModel()
    @State private var currentTime = Time(hour: 0, minute: 0, second: 0)
    var colorSet: [Color] = [Color.accentColor, Color.secondAccent, Color.thirdAccent]
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            let clockCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let clockRadius: CGFloat = min(geometry.size.width, geometry.size.height) * 0.25 // 25% of the smallest dimension
            ZStack {
                // Draw minute lines around the circle
                ForEach(0..<60) { i in
                    Path { path in
                        let angle = Double(i) * 6 * (Double.pi / 180)  // Convert angle to radians
                        let lineLength: CGFloat = i % 5 == 0 ? 10 : 5  // Longer line for every 5 minutes
                        let startPoint = CGPoint(
                            x: clockCenter.x + (clockRadius - lineLength) * CGFloat(cos(angle)),
                            y: clockCenter.y + (clockRadius - lineLength) * CGFloat(sin(angle)))
                        let endPoint = CGPoint(
                            x: clockCenter.x + clockRadius * CGFloat(cos(angle)),
                            y: clockCenter.y + clockRadius * CGFloat(sin(angle)))
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                    .stroke(Color.primary, lineWidth: i % 5 == 0 ? 2 : 1)
                }
                
                // Hour Pointer
                
                
                ForEach(viewModel.alarms.indices, id: \.self) { index in
                    let alarmDate = viewModel.alarms[index].time
                    let countdownDuration = alarmDate.timeIntervalSince(Date())
                    let alarmCircleSize = CGFloat(clockRadius*2 + 35 + CGFloat(index) * 60)
                    let endAngleDegree = 360.0 * countdownDuration / 3600
                    ArcView(radius: alarmCircleSize / 2,
                            startAngle: Angle(degrees: -90),
                            endAngle: Angle(degrees: endAngleDegree-90),
                            lineWidth: 20,
                            color: colorSet[index],
                            index: index)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    PointerView(width: 6, height: 60, color: colorSet[index], endAngle: Angle(degrees: endAngleDegree))
                }
            }
            
        }
        .frame(height: 400)
        .onReceive(timer) { _ in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: Date())
            currentTime = Time(hour: components.hour ?? 0, minute: components.minute ?? 0, second: components.second ?? 0)
        }
    }
}

struct PointerView: View {
    var width: CGFloat
    var height: CGFloat
    var color: Color
    var endAngle: Angle // The angle to which the pointer should point

    @State private var animatePointer: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            Path { path in
                // Draw the pointer path
                path.move(to: center)
                path.addLine(to: CGPoint(x: center.x, y: center.y - height / 2))
            }
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
            .rotationEffect(animatePointer ? endAngle : Angle(degrees: 0))
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatePointer = true
                }
            }
        }
        .frame(width: width, height: height, alignment: .center)
    }
}

struct ArcView: View {
    var radius: CGFloat
    var startAngle: Angle
    var endAngle: Angle
    var lineWidth: CGFloat
    var color: Color
    
    var index: Int
    
    @GestureState private var tapped = false // Tracks the tap state

    @State private var drawAnimationProgress: CGFloat = 0.0 // For drawing animation

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let tapGesture = LongPressGesture(minimumDuration: 0.01)
                .updating($tapped) { currentState, gestureState, transaction in
                    gestureState = currentState
                }
                .onEnded { _ in
                    self.arcTapped(index: index)
                }
            
            // Animated drawing of the arc
            Path { path in
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            }
            .trim(from: 0, to: drawAnimationProgress) // Use trimming for drawing animation
            .stroke(style: StrokeStyle(lineWidth: tapped ? lineWidth * 1.3 : lineWidth, lineCap: .round))
            .foregroundColor(color)
            .gesture(tapGesture)
            .animation(.easeInOut, value: tapped)
            .onAppear {
                // Trigger the drawing animation when the view appears
                withAnimation(.easeOut(duration: 1.0)) {
                    drawAnimationProgress = 1.0
                }
            }
            .onDisappear {
                withAnimation(.easeOut(duration: 1.0)) {
                    drawAnimationProgress = 0
                }
            }
            
        }
    }
    
    func arcTapped(index: Int) {
        print("Arc: ", index, " tapped")
    }
}

struct Time {
    var hour: Int
    var minute: Int
    var second: Int
    
    var hourAngle: Double {
        return (Double(hour) + Double(minute) / 60) * 30
    }
    
    var minuteAngle: Double {
        return (Double(minute) + Double(second) / 60) * 6
    }
    
    var secondAngle: Double {
        return Double(second) * 6
    }
}

struct AlarmInterfaceView_Previews: PreviewProvider {
    static var previews: some View {
        AlarmInterfaceView()
    }
}
