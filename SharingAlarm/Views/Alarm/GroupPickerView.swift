//
//  GroupPickerView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/10/6.
//

import SwiftUI

struct GroupPickerView: View {
    @Binding var selectedGroup: Groups?
    @State private var showAddGroupView = false
    @ObservedObject var groupsViewModel: GroupsViewModel
    var groups: [Groups]
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section(header: Text("Create alarm just for yourself")) {
                // Example group selection
                Button {
                    selectedGroup = nil
                    dismiss()
                } label: {
                    Text("Just For You")
                }
            }
            if !groups.isEmpty {
                Section(header: Text("Select a Group")) {
                    ForEach(groups, id: \.id) { group in
                        Button {
                            selectedGroup = group
                            dismiss()
                        } label: {
                            Text(group.name)
                        }
                    }
                }
            }
            
            Section {
                // Option to add a new group
                Button {
                    showAddGroupView = true
                } label: {
                    Text("Create a New")
                        .foregroundStyle(.systemText)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.accent)
            }
        }
        .sheet(isPresented: $showAddGroupView) {
            AddGroupView(viewModel: groupsViewModel)
        }
    }
}

#Preview {
    GroupPickerView(selectedGroup: .constant(nil), groupsViewModel: .init(), groups: [])
}
