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
    @EnvironmentObject var groupsViewModel: GroupsViewModel
    @State private var showingAddAlarm = false
    @State private var showingEditAlarm = false
    @State private var showingOngoingAlarm = false
    @State private var showingRemoveAlarm = false
    @State private var showingSkipAlarm = false
    
    @State private var selectedTime: Date? = nil
    @State private var selectedGroup = ""
    @State private var repeatInterval = ""
    @State private var selectedSound = ""
    @State private var remainingTime: TimeInterval? = nil
    @State private var sortGroup = ""
    let repeatOptions = ["None", "Daily", "Weekly"]
    let sounds = ["Harmony", "Ripples", "Signal"]
    
    var body: some View {
        VStack {
            HStack {
                Text("Alarms")
                    .font(.largeTitle.bold())
                Spacer()
//                if !viewModel.ongoingAlarms.isEmpty {
//                    Button {
//                        viewModel.showAlarmView = true
//                    } label: {
//                        Image(systemName: "alarm.fill")
//                            .resizable()
//                            .frame(width: 38, height: 40)
//                            .foregroundStyle(.accent)
//                            .padding(.trailing)
//                    }
//                }
                Menu {
                    Button {
                        viewModel.sortAlarmsByTime()
                    } label : {
                        Text("Sort By Time")
                    }
                    Menu {
                        Button {
                            sortGroup = ""
                        } label: {
                            Text("All")
                        }
                        ForEach(viewModel.groupNames.sorted{$0 < $1}, id: \.self) { name in
                            Button {
                                sortGroup = name
                            } label: {
                                Text(name)
                            }
                        }
                    } label: {
                        Text("Filter By Group")
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
            AlarmInterfaceView(viewModel: viewModel, sortGroup: sortGroup)
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
                            if sortGroup == "Just For You" {
                                // Filter by groupName or include "Just For You" alarms (where groupName is empty)
                                return alarm.groupName == nil
                            } else if sortGroup.isEmpty{
                                // If no sortGroup is selected, include all alarms
                                return true
                            } else {
                                return alarm.groupName == sortGroup
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
                                    showingRemoveAlarm = true
                                    viewModel.selectedAlarm = alarm
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                                if alarm.repeatInterval != "None" {
                                    Button {
                                        showingSkipAlarm = true
                                        viewModel.selectedAlarm = alarm
                                    } label: {
                                        Label("Skip", systemImage: "forward")
                                    }
                                    .tint(.accent)
                                }
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
        .background(
            Color(UIColor.systemGroupedBackground)
        )
        .confirmationDialog("Are you sure you want to Remove this Alarm?", isPresented: $showingRemoveAlarm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let alarm = viewModel.selectedAlarm {
                    viewModel.removeAlarm(alarm: alarm)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removing Alarm will remove it from group, thus all participants will loss the alarm. If you want to turn it off just for yourself, tap the toggle switch.")
        }
        .confirmationDialog("Are you sure you want to Skip this Alarm?", isPresented: $showingSkipAlarm, titleVisibility: .visible) {
            Button("Skip", role: .destructive) {
                if let alarm = viewModel.selectedAlarm {
                    viewModel.removeAlarm(alarm: alarm, reschedule: true)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let alarm = viewModel.selectedAlarm, alarm.repeatInterval != "None" {
                switch alarm.repeatInterval {
                case "Daily":
                    var newTargetDate = Calendar.current.date(byAdding: .day, value: 1, to: alarm.time)
                    Text("Skip the alarm for \(alarm.time.formatted(.dateTime)) and reschedule it at \(newTargetDate!.formatted(.dateTime)).")
                case "Weekly":
                    var newTargetDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: alarm.time)
                    Text("Skip the alarm for \(alarm.time.formatted(.dateTime)) and reschedule it at \(newTargetDate!.formatted(.dateTime)).")
                default:
                    Text("You cannot skip this alarm without a repeat value. This will remove the alarm")
                }
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
            AddAlarmView(viewModel: viewModel, groupsViewModel: groupsViewModel, isPresented: $showingAddAlarm)
        }
        .sheet(isPresented: $viewModel.showAlarmView) {
            AlarmView(alarmViewModel: viewModel)
        }
    }
}

//#Preview {
//    AlarmsView()
//}
