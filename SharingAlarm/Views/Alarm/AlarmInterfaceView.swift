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
    
    var sortGroup: String = ""
    
    var filteredAlarms: [Alarm] {
        viewModel.alarms.filter { alarm in
            if sortGroup == "Just For You" {
                return alarm.groupName == nil
            } else if sortGroup.isEmpty {
                return true
            } else {
                return alarm.groupName == sortGroup
            }
        }
    }

    func arcTapped(index: Int) {
        viewModel.selectedAlarm = viewModel.alarms[index]
    }
    
    var body: some View {
        GeometryReader { geometry in
            let clockCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let clockRadius: CGFloat = min(geometry.size.width, geometry.size.height) * 0.25 // 25% of the smallest dimension
            ZStack {
//                Image(systemName: "aqi.low")
//                    .resizable()
//                    .frame(width: 110, height: 120)
//                    .symbolEffect(.variableColor.cumulative.hideInactiveLayers.nonReversing, options: .repeat(3), value: $viewModel.ongoingAlarms.count != 0)
                
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
                
                ForEach(filteredAlarms.prefix(3).indices, id: \.self) { index in
                    CombineView(alarm: filteredAlarms[index], timerViewModel: TimerViewModel(targetDate: filteredAlarms[index].time), viewModel: viewModel, clockRadius: clockRadius, index: index, geometry: geometry)
                }
            }
        }
    }
}

struct CombineView: View {
    var alarm: Alarm
    @ObservedObject var timerViewModel: TimerViewModel
    @StateObject var viewModel: AlarmsViewModel
    @StateObject var arViewModel = AudioRecorderViewModel()
    @StateObject var groupViewModel = GroupsViewModel()
    var clockRadius: CGFloat
    var index: Int
    var colorSet: [Color] = [Color.accent, Color.secondAccent, Color.thirdAccent]
    var geometry: GeometryProxy
    var name = UserDefaults.standard.string(forKey: "name") ?? "SharingAlarm"
    func arcTapped() {
        viewModel.selectedAlarm = alarm
    }
    
    func setupTimerEndAction() {
        timerViewModel.onTimerEnd = {
                
            print("Alarm is ringing")
            //Present Alarm View
            // viewModel.startLongVibration()
            viewModel.showAlarmView = true
            viewModel.selectedAlarm = alarm
//            viewModel.ongoingAlarms.append(alarm)
//                    arViewModel.playSound(soundName: "/\(alarm.creatorID ?? "")/Recording.caf")
            // viewModel.removeAlarm(documentID: alarmID)
        }
    }
    
    var body: some View {
        let alarmCircleSize = CGFloat(clockRadius*2 + 35 + CGFloat(index) * 60)
        let endAngleDegree: Double = timerViewModel.timeRemaining > 7200 ?
        360.0 * (timerViewModel.timeRemaining.truncatingRemainder(dividingBy: 3600)) / 3600 + 360.0 :
        360.0 * timerViewModel.timeRemaining / 3600

        ArcView(radius: alarmCircleSize / 2,
                startAngle: Angle(degrees: -90),
                endAngle: Angle(degrees: endAngleDegree - 90),
                lineWidth: 20,
                color: colorSet[index],
                action: self.arcTapped,
                index: index,
                viewModel: viewModel)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                if let alarmID = alarm.id {
                    viewModel.timerViewModels[alarmID] = timerViewModel
                    setupTimerEndAction()
                }
            }

        PointerView(width: 6, height: 120 - CGFloat(index) * 30, color: colorSet[index], endAngle: Angle(degrees: endAngleDegree))
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
    var action: () -> Void
    var index: Int
    var viewModel: AlarmsViewModel
    
    @State private var tapped = false // Tracks the tap state
    @State private var drawAnimationProgress: CGFloat = 0.0 // For drawing animation
    @State var isShowEdit = false
    @State var isShowDetail = false

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
//            let longPressGesture = LongPressGesture(minimumDuration: 0.6, maximumDistance: .infinity)
//                .onChanged {_ in
//                    self.action()
//                }
//                .updating($tapped) { currentState, gestureState, transaction in
//                    gestureState = currentState
//                }
//                .onEnded { _ in
//                    viewModel.selectedAlarm = viewModel.alarms[index]
//                    isShowEdit = true
//                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
//                }
            
            // Animated drawing of the arc
            Path { path in
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            }
            .trim(from: 0, to: drawAnimationProgress) // Use trimming for drawing animation
            .stroke(style: StrokeStyle(lineWidth: tapped ? lineWidth * 1.3 : lineWidth, lineCap: .round))
            .foregroundColor(color)
            .onTapGesture {
                viewModel.selectedAlarm = viewModel.alarms[index]
                isShowDetail = true
            }
            .onLongPressGesture(minimumDuration: 0.6) {
                viewModel.selectedAlarm = viewModel.alarms[index]
                isShowEdit = true
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } onPressingChanged: { istapped in
                tapped = istapped
            }
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
            .sheet(isPresented: $isShowEdit) {
                if let selectedAlarm = viewModel.selectedAlarm {
                    EditAlarmView(
                        isPresented: $isShowEdit,
                        viewModel: viewModel,
                        alarm: selectedAlarm
                    )
                }
            }
            .sheet(isPresented: $isShowDetail) {
                if let selectedAlarm = viewModel.selectedAlarm {
                    AlarmDetailView(
                        viewModel: viewModel,
                        alarm: selectedAlarm
                    )
                }
            }
        }
    }
}

// Used for groups
struct PathView: View {
    var alarm: Alarm
    var radius: CGFloat = 25
    var lineWidth: CGFloat = 12
    
    var body: some View {
        let alarmTime = alarm.time.timeIntervalSinceNow
        let timeRemaining = max(0, alarmTime)
        // Calculate end angle based on time remaining
        let endAngleDegree: Double = timeRemaining > 7200
            ? 360.0 * (timeRemaining.truncatingRemainder(dividingBy: 3600)) / 3600 + 360.0
            : 360.0 * timeRemaining / 3600
        // Draw the Path if an alarm exists for this group
        VStack {
            GeometryReader { geometry in
                Path { path in
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(endAngleDegree), clockwise: false)
                }
                .stroke(Color.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            .frame(width: radius * 2.5, height: radius * 2.5) // Set a frame size for the path
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
