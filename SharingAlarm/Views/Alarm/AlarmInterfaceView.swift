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

    func arcTapped(index: Int) {
        viewModel.selectedAlarm = viewModel.alarms[index]
    }
    
    var body: some View {
        GeometryReader { geometry in
            let clockCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let clockRadius: CGFloat = min(geometry.size.width, geometry.size.height) * 0.25 // 25% of the smallest dimension
            ZStack {
                Rectangle()
                    .fill(BackgroundStyle())
                    .onTapGesture {
                        viewModel.selectedAlarm = nil
                    }
                
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
                
                ForEach(viewModel.alarms.prefix(3).indices, id: \.self) { index in
                    let alarmCircleSize = CGFloat(clockRadius*2 + 35 + CGFloat(index) * 60)
                    let endAngleDegree = 360.0 * viewModel.alarms[index].remainingTime / 3600
                    ArcView(radius: alarmCircleSize / 2,
                            startAngle: Angle(degrees: -90),
                            endAngle: Angle(degrees: endAngleDegree-90),
                            lineWidth: 20,
                            color: colorSet[index],
                            action: self.arcTapped,
                            index: index,
                            viewModel: viewModel)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    PointerView(width: 6, height: 120 - CGFloat(index) * 30, color: colorSet[index], endAngle: Angle(degrees: endAngleDegree))
                }
            }
            .onAppear {
                viewModel.startGlobalTimer()
            }
        }
        .frame(height: 400)
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
    var action: (Int) -> Void
    var index: Int
    var viewModel: AlarmsViewModel
    
    @GestureState private var tapped = false // Tracks the tap state
    @State private var drawAnimationProgress: CGFloat = 0.0 // For drawing animation
    @State var isShowDetail = false

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let tapGesture = LongPressGesture(minimumDuration: 0.6)
                .onChanged {_ in
                    self.action(index)
                }
                .updating($tapped) { currentState, gestureState, transaction in
                    gestureState = currentState
                }
                .onEnded { _ in
                    isShowDetail = true
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            
            // Animated drawing of the arc
            Path { path in
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            }
            .trim(from: 0, to: drawAnimationProgress) // Use trimming for drawing animation
            .stroke(style: StrokeStyle(lineWidth: tapped ? lineWidth * 1.3 : lineWidth, lineCap: .round))
            .foregroundColor(color)
            .gesture(tapGesture)
            .animation(.spring(duration: 0.6), value: tapped)
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
            .sheet(isPresented: $isShowDetail) {
                if let selectedAlarm = viewModel.selectedAlarm {
                    AlarmDetailView(
                        isPresented: $isShowDetail,
                        viewModel: viewModel,
                        alarm: selectedAlarm
                    )
                }
            }
        }
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
