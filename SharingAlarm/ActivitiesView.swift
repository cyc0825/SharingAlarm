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
            Group{
                if viewModel.activities.isEmpty {
                    Text("There is no activity happening")
                        .padding()
                } else {
                    List(viewModel.activities.indices, id: \.self) { index in
                        NavigationLink(destination: ActivityDetailView(activity: viewModel.activities[index])) {
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

struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var friendViewModel = FriendsViewModel()
    @ObservedObject var viewModel: ActivitiesViewModel
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var participants: [User] = []
    @State private var showingFriendPicker = false
    
    let friends: [User] = []
    let userName: String = UserDefaults.standard.value(forKey: "name") as? String ?? "Unknown"

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Activity Name")) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Activity Dates")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text("Participants")) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text(userName)
                            .fontWeight(.bold)
                    }
                    ForEach(participants.indices, id: \.self) { index in
                        Text(participants[index].name)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    participants.remove(at: index)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                    Button(action: {
                        showingFriendPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Participant")
                        }
                    }
                }
            }
            .navigationBarTitle("Add Activity", displayMode: .inline)
            .onDisappear{
                viewModel.fetchActivity()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.addActivity(name: name, startDate: startDate, endDate: endDate, participants: convertUserToUID(Users: participants)){ result in
                            switch result {
                            case .success():
                                print("Successfully add activity")
                            case .failure(let error):
                                print("Failed to add alarm: \(error.localizedDescription)")
                            }
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFriendPicker) {
                // Friend picker view goes here
                FriendPicker(selectedFriends: $participants)
            }
        }
    }
    
    func convertUserToUID(Users: [User]) -> [String] {
        var result: [String] = []
        for user in Users {
            result.append(user.uid)
        }
        return result
    }
}

struct FriendPicker: View {
    @StateObject var viewModel = FriendsViewModel()
    @Binding var selectedFriends: [User]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(viewModel.friends.indices, id: \.self) { index in
                Button(viewModel.friends[index].name) {
                    // Add the selected friend to the participants list if not already added
                    if !selectedFriends.contains(where: { $0.recordID == viewModel.friends[index].recordID }) {
                        selectedFriends.append(viewModel.friends[index])
                    }
                    dismiss()
                }
            }
            .navigationTitle("Select Friends")
            .toolbar {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.fetchFriends()
        }
    }
}
