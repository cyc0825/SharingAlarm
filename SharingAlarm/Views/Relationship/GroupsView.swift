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
                        NavigationLink(destination: GroupDetailView(viewModel: viewModel, group: group)) {
                            GroupCard(viewModel: viewModel, group: group)
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .refreshable {
                viewModel.fetchGroup()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddGroup = true
                    }) {
                        Image(systemName: "calendar.badge.plus")
                    }
                    .popoverTip(GroupsTip())
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView(viewModel: viewModel)
            }
        }
    }
}
