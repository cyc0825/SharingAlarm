//
//  AlarmsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI

struct AlarmsView: View {
    @StateObject var viewModel = AlarmsViewModel()
    @State private var showingAddAlarm = false
    
    var body: some View {
        NavigationView {
            VStack {
                Image("alarmsvg")
                    .resizable()
                    .frame(width: 300,height: 300)
                    .padding()
                
                // List of Alarms
                List {
                    ForEach(viewModel.alarms, id: \.id) { alarm in
                        NavigationLink(destination: AlarmDetailView(viewModel: viewModel, alarmId: alarm.id)) {
                            Text("Alarm at \(alarm.time.formatted(date: .omitted, time: .shortened))")
                        }
                    }
                }
                .listStyle(PlainListStyle())
                Section(header: Text("Next Alarm")) {
                    if let nextAlarm = viewModel.nextAlarm {
                        Text("Alarm at \(nextAlarm.time.formatted(date: .omitted, time: .shortened))")
                        Text("\(viewModel.timeUntilNextAlarm())")
                    } else {
                        Text("No upcoming alarms")
                    }
                }
            }
            .navigationTitle("Alarms")
            .navigationBarItems(trailing: Button(action: {
                showingAddAlarm = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView(isPresented: $showingAddAlarm) { time, repeatInterval, sound in
                    let newAlarm = Alarm(time: time, sound: sound, repeatInterval: repeatInterval)
                    viewModel.alarms.append(newAlarm)
                    scheduleNotification(for: newAlarm)
                }
            }
        }
    }
}

struct AddAlarmView: View {
    @Binding var isPresented: Bool // To dismiss the view
    @State private var selectedTime = Date()
    @State private var repeatInterval = "None"
    @State private var selectedSound = "Harmony"
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    
    var saveAction: (Date, String, String) -> Void // Closure to handle saving
    
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
            .navigationTitle("Add Alarm")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                saveAction(selectedTime, repeatInterval, selectedSound)
                isPresented = false
            })
        }
    }
}

struct AlarmDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: AlarmsViewModel
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    let alarmId: UUID
    
    var alarmIndex: Int? {
        viewModel.alarms.firstIndex(where: { $0.id == alarmId })
    }
    
    var body: some View {
        // Safely unwrap alarmIndex to ensure we're operating on valid data
        if let alarmIndex = alarmIndex {
            Form {
                DatePicker("Time", selection: $viewModel.alarms[alarmIndex].time, displayedComponents: .hourAndMinute)
                Picker("Repeat", selection: $viewModel.alarms[alarmIndex].repeatInterval) {
                    ForEach(repeatOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                Picker("Sound", selection: $viewModel.alarms[alarmIndex].sound) {
                    ForEach(sounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                
                Button("Delete Alarm") {
                    presentationMode.wrappedValue.dismiss()
                    viewModel.removeAlarm(with: alarmId)
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [alarmId.uuidString])
                }
                .foregroundColor(.red)
            }
            .navigationTitle("Edit Alarm")
        } else {
            Text("Alarm not found").onAppear {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    AlarmsView(viewModel: AlarmsViewModel())
}
