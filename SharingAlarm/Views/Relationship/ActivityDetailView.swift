//
//  ActivityDetailView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/16.
//

import SwiftUI

struct ActivityDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var viewModel: ActivitiesViewModel
    @State private var friendToDelete: String?
    @State private var showDeleteConfirmation: Bool = false
    @State private var showingEditActivity: Bool = false
    @State private var friendIDToDelete: String?
    @State private var friendIndexToDelete: Int?
    @State var activity: Activity
    
    var activityIndex: Int {
        viewModel.activities.firstIndex(where: { $0.id == activity.id }) ?? 0
    }
    
    let userID = UserDefaults.standard.value(forKey: "userID") as? String
    
    var body: some View {
        NavigationView {
            List {
                Section(header:Text("Participants")) {
                    ForEach(activity.participants.indices, id: \.self) { index in
                        if activity.participants[index].id == userID {
                            Text(activity.participants[index].name)
                                .bold()
                        } else {
                            Text(activity.participants[index].name)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        friendToDelete = activity.participants[index].name
                                        friendIDToDelete = activity.participants[index].id
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
                        Text(activity.from.formatted(date: .numeric, time: .omitted))
                    }
                    HStack {
                        Text("To:")
                        Spacer()
                        Text(activity.to.formatted(date: .numeric, time: .omitted))
                    }
                }
                
                Section {
                    Button("Delete") {
                        removeActivity()
                    }
                }
            }
        }
        .confirmationDialog("Are you sure you want to remove this friend from the group?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                guard let friendIDToDelete = friendIDToDelete else { return }
                guard let activityId = activity.id else { return }
                guard let friendIndexToDelete = friendIndexToDelete else { return }
                viewModel.removeParticipant(activityId: activityId, participantId: friendIDToDelete) { result in
                    activity.participants.remove(at: friendIndexToDelete)
                    viewModel.activities[activityIndex].participants.remove(at: friendIndexToDelete)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let friendToDelete = friendToDelete {
                Text("Would you like to remove \(friendToDelete) from the group?")
            }
        }
        .sheet(isPresented: $showingEditActivity) {
            AddActivityView(viewModel: viewModel,
                            name: activity.name,
                            startDate: activity.from,
                            endDate: activity.to,
                            participants: activity.participants,
                            editActivity: true,
                            activityId: activity.id
            )
        }
        .navigationTitle("Activity Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditActivity = true
                }
            }
        }
    }
    
    func removeActivity() {
        viewModel.removeActivity(activity: viewModel.activities[activityIndex]) { result in
            switch result {
            case .success(_):
                self.presentationMode.wrappedValue.dismiss()
                viewModel.activities.remove(at: activityIndex)
            case .failure(let error):
                debugPrint("Remove Activity error \(error.localizedDescription)")
            }
        }
    }
}
