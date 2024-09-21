//
//  DeleteProfileView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/20.
//

import SwiftUI

struct DeleteProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var presentingConfirmationDialog: Bool = false
    
    private func deleteAccount() {
        Task {
            if await authViewModel.deleteAccount() == true {
                print("Successfully deleting account")
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                Text("Please be careful, once you delete your account, you will not be able to recover it. All the information you have shared will be deleted.")
            }
            
            Section {
                Button(role: .destructive, action: { presentingConfirmationDialog.toggle() }) {
                    HStack {
                        Image(systemName: "trash.square")
                        Text("Delete Account")
                    }
                    .foregroundStyle(Color.systemText)
                }
                .listRowBackground(Color.red)
            }
        }
        .confirmationDialog("Deleting your account is permanent. Do you want to delete your account?",
                            isPresented: $presentingConfirmationDialog, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive, action: deleteAccount)
            Button("Cancel", role: .cancel, action: { })
        }
    }
}
