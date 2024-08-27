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
    @State private var sortActivity = ""
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
                                sortActivity = ""
                            } label: {
                                Text("All")
                            }
                            ForEach(viewModel.activityNames.sorted{$0 < $1}, id: \.self) { name in
                                Button {
                                    sortActivity = name
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
                AlarmInterfaceView(viewModel: viewModel, sortActivity: sortActivity)
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
                                    Spacer()
                                }
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showingAddAlarm = true
                                }
                            }
                            .scrollDisabled(true)
                            .listStyle(.plain)
                            .toolbarTitleDisplayMode(.inline)
                        }
                        // List with fixed height
                        else {
                            List($viewModel.alarms.filter { $alarm in
                                if sortActivity == "Just For You" {
                                    // Filter by activityName or include "Just For You" alarms (where activityName is empty)
                                    return alarm.activityName == nil
                                } else if sortActivity.isEmpty{
                                    // If no sortActivity is selected, include all alarms
                                    return true
                                } else {
                                    return alarm.activityName == sortActivity
                                }
                            }, id: \.id) { $alarm in
                                Button(action: {
                                    viewModel.selectedAlarm = alarm
                                    viewModel.showAlarmView = true
                                }, label: {
                                    AlarmCardView(alarm: $alarm)
                                })
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        viewModel.removeAlarm(documentID: alarm.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                                .listRowBackground(Color.clear)
                            }
                            .listStyle(.plain)
                            .toolbarTitleDisplayMode(.inline)
                        }
                        // Gradient overlay
                        VStack {
                            Spacer()
                            LinearGradient(gradient: Gradient(colors: [Color.clear, Color(UIColor.systemGroupedBackground)]), startPoint: .center, endPoint: .bottom)
                        }
                        .allowsHitTesting(false)
                    }
                }
            }
//            .onAppear{
//                viewModel.fetchAlarmData()
//                viewModel.startListeningAlarms()
//            }
//            .onDisappear{
//                viewModel.stopListeningAlarms()
//            }
            .background(
                Color(UIColor.systemGroupedBackground)
            )
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

//#Preview {
//    AlarmsView()
//}
