//
//  ProfileSetupView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/7.
//

import SwiftUI

struct ProfileSetupView: View {
    var initialUsername: String
    var initialUid: String
    var onSubmit: (String, String) -> Void
        
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var username: String = ""
    @State private var uid: String = ""
    @State private var isChecking = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var usernameWarning: String?
    @State private var uidWarning: String?
    @Environment(\.dismiss) var dismiss
    
    init(initialUsername: String, initialUid: String, onSubmit: @escaping (String, String) -> Void) {
        self.initialUsername = initialUsername
        self.initialUid = initialUid
        self.onSubmit = onSubmit
        _username = State(initialValue: initialUsername)
        _uid = State(initialValue: initialUid)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Welcome Text at the top
                Section {
                    // Username TextField
                    TextField("Name", text: $username)
                    if let usernameWarning = usernameWarning {
                        Text(usernameWarning)
                            .foregroundColor(.red)
                    }
                    // Unique Identifier TextField
                    TextField("Unique Identifier", text: $uid)
                    if let uidWarning = uidWarning {
                        Text(uidWarning)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Enter your name and your unique identifier to let your friends find you!")
                        .font(.title3.bold())
                }
                .headerProminence(.increased)
                
                Section {
                    Button(action: validateAndSubmit, label: {
                        HStack {
                            Spacer()
                            Text("Go")
                            Spacer()
                        }
                        .foregroundStyle(Color.system)
                    })
                    .listRowBackground(Color.accent)
                }
            }
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button(action: validateAndSubmit, label: {
//                        Text("Save")
//                    })
//                }
//            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            //.background(Color(UIColor.systemGray6))
            //.edgesIgnoringSafeArea(.all)
        }
        .presentationDetents([.fraction(0.4)])
    }
    
    private func validateAndSubmit() {
        // Reset warnings
        usernameWarning = nil
        uidWarning = nil
        
        var isValid = true
        
        // Check for empty fields
        if username.isEmpty {
            print("Name cannot be empty")
            usernameWarning = "Name cannot be empty"
            isValid = false
        }
        
        if uid.isEmpty {
            print("Unique Identifier cannot be empty")
            uidWarning = "Unique Identifier cannot be empty"
            isValid = false
        } else {
            if uid != initialUid {
                // Additional check if UID is changed and needs to be unique
                userViewModel.checkIfUIDExists(uid: uid) { exist in
                    if exist {
                        // Proceed with submission if both checks pass
                        uidWarning = "Someone else has taken this UID, think about another one"
                        isValid = false
                    }
                }
            }
        }
        if isValid {
            if initialUid == uid && username == initialUsername {
                dismiss()
            } else {
                onSubmit(username, uid)
            }
        }
    }
}

#Preview {
    ProfileSetupView(initialUsername: "", initialUid: "", onSubmit: {_,_ in 
        print("Submit")
    })
}
