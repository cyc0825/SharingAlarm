//
//  LogsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: ActivitiesViewModel
    @State private var showingAddActivity = false
    var body: some View {
        NavigationView {
            ZStack{
                if viewModel.activities.isEmpty {
                    List {
                        Text("There is no activity happening")
                            .padding()
                    }
                } else {
                    List(viewModel.activities.indices, id: \.self) { index in
                        NavigationLink(destination: ActivityDetailView(viewModel: viewModel, activity: viewModel.activities[index])) {
                            ActivityCard(viewModel: viewModel, index: index)
                        }
                    }
                }
            }
            .navigationTitle("Activities")
            .refreshable {
                viewModel.fetchActivity()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddActivity = true
                    }) {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView(viewModel: viewModel)
            }
        }
    }
}
