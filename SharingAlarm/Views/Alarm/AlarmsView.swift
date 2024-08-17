//
//  AlarmsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI
import CloudKit

struct AlarmsView: View {
    @EnvironmentObject var viewModel: AlarmsViewModel
    @State private var showingAddAlarm = false
    @State private var showingEditAlarm = false
    @State private var showingOngoingAlarm = false
    
    @State private var selectedTime: Date? = nil
    @State private var selectedGroup = ""
    @State private var repeatInterval = ""
    @State private var selectedSound = ""
    @State private var remainingTime: TimeInterval? = nil
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Alarms")
                        .font(.largeTitle.bold())
                    Spacer()
                    if !viewModel.ongoingAlarms.isEmpty {
                        Button {
                            viewModel.showAlarmView = true
                        } label: {
                            Image(systemName: "alarm.fill")
                                .resizable()
                                .frame(width: 38, height: 40)
                                .foregroundStyle(.accent)
                                .padding(.trailing)
                        }
                    }
                    Menu {
                        Button {
                            viewModel.sortAlarmsByTime()
                        } label : {
                            Text("Sort By Time")
                        }
                        Menu {
                            Button {
                                viewModel.restoreAlarms()
                            } label: {
                                Text("All")
                            }
                            ForEach(viewModel.activityNames.sorted{$0 < $1}, id: \.self) { name in
                                Button {
                                    viewModel.filterAlarmsByActivity(activityName: name)
                                } label: {
                                    Text(name)
                                }
                            }
                        } label: {
                            Text("Filter By Activity")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .resizable()
                            .frame(width: 38, height: 35)
                    }
                    .padding(.trailing)
                    Button {
                        showingAddAlarm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }

                }
                .padding(.top, 20)
                .padding()
                AlarmInterfaceView(viewModel: viewModel)
                GeometryReader { geometry in
                    ZStack {
                        if viewModel.alarms.isEmpty {
                            List {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("No Alarm")
                                            .font(.title)
                                            .foregroundColor(.systemText)
                                        HStack {
                                            Text("Tap")
                                                .foregroundColor(.systemText)
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundStyle(.accent)
                                            Text("to add your alarm")
                                                .foregroundColor(.systemText)
                                        }
                                    }
                                    .onTapGesture {
                                        showingAddAlarm = true
                                    }
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listStyle(.plain)
                            .toolbarTitleDisplayMode(.inline)
                        }
                        // List with fixed height
                        List($viewModel.alarms, id: \.id) { $alarm in
                            Button(action: {
                                viewModel.selectedAlarm = alarm
                                showingEditAlarm = true
                            }, label: {
                                AlarmCardView(alarm: $alarm)
                            })
                        }
                        .listRowBackground(Color.clear)
                        .listStyle(.plain)
                        .toolbarTitleDisplayMode(.inline)
                        
                        // Gradient overlay
                        VStack {
                            Spacer()
                            LinearGradient(gradient: Gradient(colors: [Color.clear, Color.system]), startPoint: .center, endPoint: .bottom)
                        }
                        .allowsHitTesting(false)
                    }
                }
//                VStack{
//                    Spacer()
//                    Button(action: {showingAddAlarm = true}, label: {
//                        Text("Add Alarm")
//                            .frame(maxWidth: .infinity, minHeight: 50)
//                    })
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: UIScreen.main.bounds.width*4/5, minHeight: 50)
//                    .background(Color.brown)
//                    .cornerRadius(25)
//                    .padding(.vertical)
//                }
                
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
                // viewModel.startListeningAlarms()
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
            .sheet(isPresented: $showingEditAlarm) {
                if let selectedAlarm = viewModel.selectedAlarm {
                    EditAlarmView(
                        isPresented: $showingEditAlarm,
                        viewModel: viewModel,
                        alarm: selectedAlarm
                    )
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView(viewModel: viewModel, isPresented: $showingAddAlarm)
            }
            .sheet(isPresented: $viewModel.showAlarmView) {
                AlarmView(alarmViewModel: viewModel)
            }
        }
    }
}

#Preview {
    AlarmsView()
}
