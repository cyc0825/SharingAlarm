//
//  AlarmsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI
import CloudKit

struct AlarmsView: View {
    @StateObject var viewModel = AlarmsViewModel()
    @State private var showingAddAlarm = false
    @State private var showingEditAlarm = false
    
    @State private var selectedTime: Date? = nil
    @State private var selectedGroup = ""
    @State private var repeatInterval = ""
    @State private var selectedSound = ""
    @State private var remainingTime: TimeInterval? = nil
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    
    func formatTimeInterval(_ interval: TimeInterval?) -> String {
        if let interval = interval {
            if interval >= 86400 {  // 86400 seconds in 24 hours
                return "more than one day"
            } else if interval > 0{
                let hours = Int(interval) / 3600  // Calculate total hours
                let minutes = (Int(interval) % 3600) / 60  // Calculate remaining minutes
                
                // Formatting string to show "xx hours xx mins"
                var formattedString = ""
                if hours > 0 {
                    formattedString += "\(hours) hour" + (hours > 1 ? "s " : " ")
                }
                if minutes > 0 {
                    formattedString += "\(minutes) min" + (minutes > 1 ? "s" : "")
                }
                return formattedString.trimmingCharacters(in: .whitespaces)
            } else {
                return "Time passed"
            }
        } else {
            return ""
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                AlarmInterfaceView(viewModel: viewModel)
                
                VStack{
                    Spacer()
                    VStack{
                        Text("Alarm Details").font(.headline)
                            .padding(.vertical)
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 10) {
                                
                                DetailRow(key: "Time", value: selectedTime?.formatted(date: .omitted, time: .shortened) ?? "")
                                DetailRow(key: "Repeat", value: repeatInterval)
                                DetailRow(key: "Remaining", value: formatTimeInterval(remainingTime))
                            }
                            .frame(maxWidth: .infinity)
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 10) {
                                DetailRow(key: "Group", value: selectedGroup)
                                DetailRow(key: "Sound", value: selectedSound)
                                DetailRow(key: "Next Auto-Schedule", value: selectedGroup)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .listStyle(GroupedListStyle())
                    }
                    
                    .frame(width: UIScreen.main.bounds.width*7/8)
                    
                    if viewModel.selectedAlarm != nil {
                        Button(action: {showingEditAlarm = true}, label: {
                            Text("Edit Alarm")
                                .frame(maxWidth: .infinity, minHeight: 50)
                        })
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: UIScreen.main.bounds.width*4/5, minHeight: 50)
                        .background(Color.brown)
                        .cornerRadius(25)
                        .padding(.vertical)
                    } else {
                        Button(action: {showingAddAlarm = true}, label: {
                            Text("Add Alarm")
                                .frame(maxWidth: .infinity, minHeight: 50)
                        })
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: UIScreen.main.bounds.width*4/5, minHeight: 50)
                        .background(Color.brown)
                        .cornerRadius(25)
                        .padding(.vertical)
                    }
                }
                
//                Section(header: Text("Next Alarm")) {
//                    if let nextAlarm = viewModel.nextAlarm {
//                        Text("Alarm at \(nextAlarm.time.formatted(date: .omitted, time: .shortened))")
//                        Text("\(viewModel.timeUntilNextAlarm())")
//                    } else {
//                        Text("No upcoming alarms")
//                    }
//                }
            }
            .onAppear{
                viewModel.fetchAlarmData()
            }
            .onChange(of: viewModel.selectedAlarm) {
                if let selectedAlarm = viewModel.selectedAlarm {
                    selectedTime = selectedAlarm.time
                    repeatInterval = selectedAlarm.repeatInterval
                    selectedSound = selectedAlarm.sound
                    remainingTime = selectedAlarm.remainingTime
                } else {
                    selectedTime = nil
                    repeatInterval = ""
                    selectedSound = ""
                    remainingTime = nil
                }
            }
            .navigationTitle("Alarms")
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView(viewModel: viewModel, isPresented: $showingAddAlarm)
            }
            .sheet(isPresented: $showingEditAlarm) {
                if let selectedAlarm = viewModel.selectedAlarm {
                    AlarmDetailView(
                        isPresented: $showingEditAlarm,
                        viewModel: viewModel,
                        alarm: selectedAlarm
                    )
                }
            }
        }
    }
}

struct AddAlarmView: View {
    @ObservedObject var viewModel: AlarmsViewModel
    @Binding var isPresented: Bool // To dismiss the view
    @State private var selectedTime = Date()
    @State private var repeatInterval = "None"
    @State private var selectedSound = "Harmony"
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                
                Picker("Repeat", selection: $repeatInterval) {
                    ForEach(repeatOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                Picker("Sound", selection: $selectedSound) {
                    ForEach(sounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
            }
            .onDisappear {
                viewModel.fetchAlarmData()
            }
            .navigationBarTitle("Add Alarm", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                viewModel.saveAlarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval)
                let newAlarm = Alarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval)
                scheduleNotification(for: newAlarm, viewModel: viewModel)
                isPresented = false
            })
        }
    }
}

struct AlarmDetailView: View {
    @Binding var isPresented: Bool // To dismiss the view
    @ObservedObject var viewModel: AlarmsViewModel
    @State var selectedTime = Date()
    @State private var repeatInterval = "None"
    @State private var selectedSound = "Harmony"
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    let alarm: Alarm
    
    var alarmIndex: Int {
        viewModel.alarms.firstIndex(where: { $0 == alarm }) ?? 0
    }
    
    init(isPresented: Binding<Bool>, viewModel: AlarmsViewModel, alarm: Alarm) {
        self._isPresented = isPresented
        self.viewModel = viewModel
        self._selectedTime = State(initialValue: viewModel.selectedAlarm?.time ?? Date())
        self._repeatInterval = State(initialValue: viewModel.selectedAlarm?.repeatInterval ?? "None")
        self._selectedSound = State(initialValue:viewModel.selectedAlarm?.sound ?? "Harmony")
        self.alarm = alarm
    }
    
    var body: some View {
        NavigationView {
            // Safely unwrap alarmIndex to ensure we're operating on valid data
            if let selectedAlarm = viewModel.selectedAlarm {
                Form {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    
                    Picker("Repeat", selection: $repeatInterval) {
                        ForEach(repeatOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    Picker("Sound", selection: $selectedSound) {
                        ForEach(sounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    
//                    Button("Delete Alarm", role: .destructive) {
//                        viewModel.removeAlarm(recordID: viewModel.alarms[alarmIndex].recordID) { result in
//                            viewModel.selectedAlarm = nil
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                                switch result {
//                                case .success():
//                                    viewModel.alarms.remove(at: alarmIndex)
//                                case .failure(let error):
//                                    print("Failed to remove alarm: \(error.localizedDescription)")
//                                }
//                            }
//                        }
//                    }
//                    .foregroundColor(.red)
                }
                .onDisappear {
                    viewModel.fetchAlarmData()
                }
                .navigationBarTitle("Edit Alarm", displayMode: .inline)
                .navigationBarItems(leading: Button("Cancel") {
                    isPresented = false
                }, trailing: Button("Save") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel.alarms.remove(at: alarmIndex)
                    }
                    let newAlarm = Alarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval, notificationIdentifier: selectedAlarm.notificationIdentifier)
                    modifyNotification(for: newAlarm, viewModel: viewModel)
                    isPresented = false
                })
            }
        }
        
    }
}

struct DetailRow: View {
    var key: String
    var value: String

    var body: some View {
        HStack {
            Text(key)
                .fontWeight(.bold)
                .font(.footnote)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .font(.footnote)
        }
    }
}

#Preview {
    AlarmsView()
}
