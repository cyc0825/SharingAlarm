//
//  AddGroupView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/7/28.
//

import SwiftUI

struct AddGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var friendViewModel = FriendsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject var viewModel: GroupsViewModel
    @State var userName: String = UserDefaults.standard.value(forKey: "name") as? String ?? ""
    @State public var name = ""
    @State public var startDate = Date()
    @State public var endDate = Date()
    @State public var participants: [AppUser] = []
    @State public var showingFriendPicker = false
    
    var editGroup: Bool = false
    var groupId: String?
    
    var groupIndex: Int {
        viewModel.groups.firstIndex(where: { $0.id == groupId }) ?? 0
    }
    
    @State public var addedParticipants: [AppUser] = []
    
    let friends: [AppUser] = []

    var body: some View {
        VStack {
            Spacer()
            NavigationView {
                List {
                    Section(header: Text("Group Name")) {
                        TextField("Name", text: $name)
                    }
                    
                    Section(header: Text("Group Dates")) {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                    
                    Section(header: Text("Participants")) {
                        if !editGroup {
                            HStack {
                                Image(systemName: "star.fill")
                                Text(userName)
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
                        if editGroup {
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
                .navigationBarTitle(editGroup ? "Edit Group" : "Add Group", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            editGroup ? EditGroup() : saveGroup()
                        }
                    }
                }
                .sheet(isPresented: $showingFriendPicker) {
                    // Friend picker view goes here
                    if editGroup {
                        AddFriendPicker(selectedFriends: $participants, addedParticipants: $addedParticipants)
                    } else {
                        FriendPicker(selectedFriends: $participants)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    func saveGroup() {
        var temp = participants
        temp.append(userViewModel.appUser)
        viewModel.addGroup(name: name, startDate: startDate, endDate: endDate, participants: temp) { result in
            switch result {
            case .success(let group):
                viewModel.groups.append(group)
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                debugPrint("Add Group error: \(error)")
            }
        }
    }
    
    func EditGroup() {
        viewModel.editGroup(groupId: groupId!, name: name, startDate: startDate, endDate: endDate, newParticipants: addedParticipants) { result in
            switch result {
            case .success(let addedParticipants):
                viewModel.groups[groupIndex].participants.append(contentsOf: addedParticipants)
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                debugPrint("Add Group error: \(error)")
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
            VStack {
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
                Text("Did not find your friends? Go to FRIENDS tab and make sure they are added to your friends list.")
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
