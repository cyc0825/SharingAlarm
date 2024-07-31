//
//  AddActivityView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/7/28.
//

import SwiftUI

struct AddActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var friendViewModel = FriendsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: ActivitiesViewModel
    @State var userViewModel = UserViewModel()
    @State public var name = ""
    @State public var startDate = Date()
    @State public var endDate = Date()
    @State public var participants: [AppUser] = []
    @State public var showingFriendPicker = false
    
    var editActivity: Bool = false
    var activityId: String?
    
    var activityIndex: Int {
        viewModel.activities.firstIndex(where: { $0.id == activityId }) ?? 0
    }
    
    @State public var addedParticipants: [AppUser] = []
    
    let friends: [AppUser] = []

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
                    if !editActivity {
                        HStack {
                            Image(systemName: "star.fill")
                            Text(userViewModel.appUser.name)
                                .fontWeight(.bold)
                        }
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
                    if editActivity {
                        ForEach(addedParticipants.indices, id: \.self) { index in
                            Text(addedParticipants[index].name)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        addedParticipants.remove(at: index)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
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
            .navigationBarTitle(editActivity ? "Edit Activity" : "Add Activity", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        editActivity ? EditActivity() : saveActivity()
                    }
                }
            }
            .sheet(isPresented: $showingFriendPicker) {
                // Friend picker view goes here
                if editActivity {
                    AddFriendPicker(selectedFriends: $participants, addedParticipants: $addedParticipants)
                } else {
                    FriendPicker(selectedFriends: $participants)
                }
            }
        }
    }
    func saveActivity() {
        var temp = participants
        temp.append(userViewModel.appUser)
        viewModel.addActivity(name: name, startDate: startDate, endDate: endDate, participants: temp) { result in
            switch result {
            case .success(let activity):
                viewModel.activities.append(activity)
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                debugPrint("Add Activity error: \(error)")
            }
        }
    }
    
    func EditActivity() {
        viewModel.editActivity(activityId: activityId!, name: name, startDate: startDate, endDate: endDate, newParticipants: addedParticipants) { result in
            switch result {
            case .success(let addedParticipants):
                viewModel.activities[activityIndex].participants.append(contentsOf: addedParticipants)
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                debugPrint("Add Activity error: \(error)")
            }
        }
    }
}

struct FriendPicker: View {
    @StateObject var viewModel = FriendsViewModel()
    @Binding var selectedFriends: [AppUser]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(viewModel.friends.indices, id: \.self) { index in
                if !selectedFriends.contains(where: { $0.uid == viewModel.friends[index].friendRef.uid }) {
                    Button(viewModel.friends[index].friendRef.name) {
                        // Add the selected friend to the participants list if not already added
                        selectedFriends.append(viewModel.friends[index].friendRef)
                        dismiss()
                    }
                } else {
                    Text(viewModel.friends[index].friendRef.name)
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

struct AddFriendPicker: View {
    @StateObject var viewModel = FriendsViewModel()
    @Binding var selectedFriends: [AppUser]
    @Binding var addedParticipants: [AppUser]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(viewModel.friends.indices, id: \.self) { index in
                if !selectedFriends.contains(where: { $0.uid == viewModel.friends[index].friendRef.uid }) {
                    if !addedParticipants.contains(where: { $0.uid == viewModel.friends[index].friendRef.uid }) {
                        Button(viewModel.friends[index].friendRef.name) {
                            // Add the selected friend to the participants list if not already added
                            addedParticipants.append(viewModel.friends[index].friendRef)
                            dismiss()
                        }
                    } else {
                        Text(viewModel.friends[index].friendRef.name)
                    }
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
