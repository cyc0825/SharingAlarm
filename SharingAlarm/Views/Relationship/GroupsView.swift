//
//  LogsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI
import TipKit

struct GroupsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var alarmsViewModel: AlarmsViewModel
    @EnvironmentObject var viewModel: GroupsViewModel
    @State private var showingAddGroup = false
    var body: some View {
        NavigationStack {
            ZStack{
                if viewModel.groups.isEmpty {
                    List {
                        Text("There is no group currently")
                            .padding()
                    }
                } else {
                    List(viewModel.groups, id: \.self) { group in
                        var alarmsForGroup: [Alarm] {
                            alarmsViewModel.alarms.filter { $0.groupId == group.id }
                        }
                        ZStack {
                            GroupCard(viewModel: viewModel, alarmsViewModel: alarmsViewModel, group: group, alarmsForGroup: alarmsForGroup)
                            NavigationLink(destination: GroupDetailView(viewModel: viewModel, group: group, alarmsForGroup: alarmsForGroup)) {
                                EmptyView()
                            }
                            .opacity(0.0)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color(UIColor.systemGroupedBackground))  // Clear list row background
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Groups")
            .refreshable {
                viewModel.fetchGroup()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 17.0, *) {
                        Button(action: {
                            showingAddGroup = true
                        }) {
                            Image(systemName: "calendar.badge.plus")
                        }
                        .popoverTip(GroupsTip())
                    } else {
                        // Fallback on earlier versions
                        Button(action: {
                            showingAddGroup = true
                        }) {
                            Image(systemName: "calendar.badge.plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView(viewModel: viewModel)
            }
        }
    }
}
