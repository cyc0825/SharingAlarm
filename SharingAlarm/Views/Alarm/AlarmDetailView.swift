//
//  AlarmDetailView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/7/28.
//

import SwiftUI

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
