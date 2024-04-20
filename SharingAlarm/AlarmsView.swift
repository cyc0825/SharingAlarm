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
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    
    func remainingTime(from startDate: Date, to endDate: Date?) -> String {
            guard let endDate = endDate else { return "" }

            let components = Calendar.current.dateComponents([.day, .hour, .minute], from: startDate, to: endDate)
            let formattedComponents = [
                components.day.flatMap { $0 > 0 ? "\($0) day" + ($0 == 1 ? "" : "s") : nil },
                components.hour.flatMap { $0 > 0 ? "\($0) hour" + ($0 == 1 ? "" : "s") : nil },
                components.minute.flatMap { $0 > 0 ? "\($0) minute" + ($0 == 1 ? "" : "s") : nil }
            ].compactMap { $0 }.joined(separator: ", ")

            return formattedComponents.isEmpty ? "Time passed" : formattedComponents
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
                                DetailRow(key: "Remaining", value: remainingTime(from: Date(), to: selectedTime))
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
                    
                    if let selectedAlarm = viewModel.selectedAlarm {
                        NavigationLink(destination: AlarmDetailView(viewModel: viewModel, alarm: selectedAlarm)) {
                            Text("Edit Alarm")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: UIScreen.main.bounds.width*4/5, minHeight: 50)
                            .background(Color.brown)
                            .cornerRadius(25)
                            .padding(.vertical)
                        }
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
                viewModel.fetchUpdatedRecords()
            }
            .onChange(of: viewModel.selectedAlarm) {
                if let selectedAlarm = viewModel.selectedAlarm {
                    selectedTime = selectedAlarm.time
                    repeatInterval = selectedAlarm.repeatInterval
                    selectedSound = selectedAlarm.sound
                } else {
                    selectedTime = nil
                    repeatInterval = ""
                    selectedSound = ""
                }
            }
            .refreshable {
                viewModel.fetchUpdatedRecords()
            }
            .navigationTitle("Alarms")
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView(isPresented: $showingAddAlarm) { time, repeatInterval, sound in
                    viewModel.addAlarm(time: time, sound: sound, repeatInterval: repeatInterval) { result in
                        switch result {
                        case .success(let newAlarm):
                            scheduleNotification(for: newAlarm)
                            print("add successfully")
                        case .failure(let error):
                            print("Failed to add alarm: \(error.localizedDescription)")
                        }}
                    
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
    @ObservedObject var viewModel: AlarmsViewModel
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    let alarm: Alarm
    
    var alarmIndex: Int {
        viewModel.alarms.firstIndex(where: { $0 == alarm }) ?? 0
    }

    var body: some View {
        // Safely unwrap alarmIndex to ensure we're operating on valid data
        if viewModel.selectedAlarm != nil {
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
                    viewModel.removeAlarm(recordID: viewModel.alarms[alarmIndex].recordID) { result in
                        viewModel.selectedAlarm = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            switch result {
                            case .success():
                                viewModel.alarms.remove(at: alarmIndex)
                            case .failure(let error):
                                print("Failed to remove alarm: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                .foregroundColor(.red)
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
