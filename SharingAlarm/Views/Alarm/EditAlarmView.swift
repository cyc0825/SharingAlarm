//
//  EditAlarmView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/7/28.
//

import SwiftUI

struct EditAlarmView: View {
    @Binding var isPresented: Bool // To dismiss the view
    @ObservedObject var viewModel: AlarmsViewModel
    @State var selectedTime = Date()
    @State private var repeatInterval = "None"
    @State private var selectedSound = "Harmony"
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony.mp3", "Ripples", "Signal"]
    let alarm: Alarm
    
    var alarmIndex: Int {
        viewModel.alarms.firstIndex(where: { $0 == alarm }) ?? 0
    }
    
    init(isPresented: Binding<Bool>, viewModel: AlarmsViewModel, alarm: Alarm) {
        self._isPresented = isPresented
        self.viewModel = viewModel
        self._selectedTime = State(initialValue: viewModel.selectedAlarm?.time ?? Date())
        self._repeatInterval = State(initialValue: viewModel.selectedAlarm?.repeatInterval ?? "None")
        self._selectedSound = State(initialValue:viewModel.selectedAlarm?.sound ?? "Harmony.mp3")
        self.alarm = alarm
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            // Safely unwrap alarmIndex to ensure we're operating on valid data
            if viewModel.selectedAlarm != nil {
                Form {
                    Section {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text("\(formattedDate(selectedTime))")
                        }
                        HStack {
                            Text("Repeat")
                            Spacer()
                            Text("\(repeatInterval)")
                        }
                        
                        HStack {
                            Text("Sound")
                            Spacer()
                            Text("\(selectedSound)")
                        }
                    }
                    Section {
                        Button("Delete Alarm", role: .destructive) {
                            viewModel.removeAlarm(documentID: alarm.id)
                        }
                        .foregroundColor(.red)
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .navigationBarTitle("Alarm Detail", displayMode: .inline)
                .navigationBarItems(leading: Button("Back") {
                    isPresented = false
                }
//                                    trailing: Button("Save") {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                        viewModel.alarms.remove(at: alarmIndex)
//                    }
//                    let newAlarm = Alarm(time: selectedTime, sound: selectedSound, repeatInterval: repeatInterval, notificationIdentifier: selectedAlarm.notificationIdentifier)
//                    modifyNotification(for: newAlarm, viewModel: viewModel)
//                    isPresented = false
//                }
                )
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
