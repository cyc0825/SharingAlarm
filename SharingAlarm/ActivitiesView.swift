//
//  LogsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI

struct ActivitiesView: View {
    @StateObject var viewModel = ActivitiesViewModel()
    @State private var showingAddActivity = false
    var body: some View {
        NavigationView {
            Group{
                if viewModel.activities.isEmpty {
                    Text("There is no activity currently")
                        .padding()
                } else {
                    List(viewModel.activities.indices, id: \.self) { index in
                        ActivityCard(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Activities")
        }
        .navigationBarItems(trailing: Button(action: {
            showingAddActivity = true
        }) {
            Image(systemName: "calendar.badge.plus")
        })
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView()
        }
    }
}

struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            VStack {
                Text("Add")
            }
            .navigationBarTitle("Add Activity", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .navigationBarItems(leading: Button("Save") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
