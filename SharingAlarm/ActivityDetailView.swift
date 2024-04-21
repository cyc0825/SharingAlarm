//
//  ActivityDetailView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/16.
//

import SwiftUI

struct ActivityDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var viewModel: ActivitiesViewModel
    @State private var friendToDelete: String?
    let activity: Activity
    
    var activityIndex: Int {
        viewModel.activities.firstIndex(where: { $0.recordID == activity.recordID }) ?? 0
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Participants")) {
                    ForEach(activity.participants.indices, id: \.self) { index in
                        Text(activity.participants[index].name)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    friendToDelete = activity.participants[index].name
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                }
                
                Section {
                    Button("Delete") {
                        viewModel.removeActivity(recordID: viewModel.activities[activityIndex].recordID) { result in
                            switch result {
                            case .success():
                                self.presentationMode.wrappedValue.dismiss()
                                viewModel.activities.remove(at: activityIndex)
                            case .failure(let error):
                                print("Failed to remove activity: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Activity Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
