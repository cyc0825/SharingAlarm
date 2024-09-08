//
//  GroupDetailView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/16.
//

import SwiftUI

struct GroupDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var viewModel: GroupsViewModel
    @State private var friendToDelete: String?
    @State private var showDeleteConfirmation: Bool = false
    @State private var showingEditGroup: Bool = false
    @State private var friendIDToDelete: String?
    @State private var friendIndexToDelete: Int?
    @State var group: Groups
    
    var groupIndex: Int {
        viewModel.groups.firstIndex(where: { $0.id == group.id }) ?? 0
    }
    
    let userID = UserDefaults.standard.value(forKey: "userID") as? String
    
    var body: some View {
        NavigationView {
            List {
                Section(header:Text("Participants")) {
                    ForEach(group.participants.indices, id: \.self) { index in
                        if group.participants[index].id == userID {
                            Text(group.participants[index].name)
                                .bold()
                        } else {
                            Text(group.participants[index].name)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        friendToDelete = group.participants[index].name
                                        friendIDToDelete = group.participants[index].id
                                        friendIndexToDelete = index
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                }
                
                Section(header:Text("Date")) {
                    HStack {
                        Text("From:")
                        Spacer()
                        Text(group.from.formatted(date: .numeric, time: .omitted))
                    }
                    HStack {
                        Text("To:")
                        Spacer()
                        Text(group.to.formatted(date: .numeric, time: .omitted))
                    }
                }
                
                Section {
                    Button("Delete") {
                        removeGroup()
                    }
                }
            }
        }
        .confirmationDialog("Are you sure you want to remove this friend from the group?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                guard let friendIDToDelete = friendIDToDelete else { return }
                guard let groupId = group.id else { return }
                guard let friendIndexToDelete = friendIndexToDelete else { return }
                viewModel.removeParticipant(groupId: groupId, participantId: friendIDToDelete) { result in
                    group.participants.remove(at: friendIndexToDelete)
                    viewModel.groups[groupIndex].participants.remove(at: friendIndexToDelete)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let friendToDelete = friendToDelete {
                Text("Would you like to remove \(friendToDelete) from the group?")
            }
        }
        .sheet(isPresented: $showingEditGroup) {
            AddGroupView(viewModel: viewModel,
                            name: group.name,
                            startDate: group.from,
                            endDate: group.to,
                            participants: group.participants,
                            editGroup: true,
                            groupId: group.id
            )
        }
        .navigationTitle("Group Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditGroup = true
                }
            }
        }
    }
    
    func removeGroup() {
        viewModel.removeGroup(group: viewModel.groups[groupIndex]) { result in
            switch result {
            case .success(_):
                viewModel.groups.remove(at: groupIndex)
                self.presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                debugPrint("Remove Groups error \(error.localizedDescription)")
            }
        }
    }
}
