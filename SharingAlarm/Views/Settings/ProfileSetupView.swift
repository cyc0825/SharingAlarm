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
    
    init(initialUsername: String, initialUid: String, onSubmit: @escaping (String, String) -> Void) {
        self.initialUsername = initialUsername
        self.initialUid = initialUid
        self.onSubmit = onSubmit
        _username = State(initialValue: initialUsername)
        _uid = State(initialValue: initialUid)
    }
    
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    // Welcome Text at the top
                    Text("Enter your name and your unique identifier to let your friends find you!")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .padding()
                    // Username TextField
                    TextField("Name", text: $username)
                        .textFieldStyle(LargeTextFieldStyle())
                        .padding(.horizontal)
                    if let usernameWarning = usernameWarning {
                        Text(usernameWarning)
                            .foregroundColor(.red)
                    }
                    // Unique Identifier TextField
                    TextField("Unique Identifier", text: $uid)
                        .textFieldStyle(LargeTextFieldStyle())
                        .padding(.horizontal)
                    if let uidWarning = uidWarning {
                        Text(uidWarning)
                            .foregroundColor(.red)
                    }
                    
//                    Button(action: validateAndSubmit, label: {
//                        Text("Go")
//                            .font(.title2)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity, minHeight: 50)
//                    })
//                    .background(Color.accentColor)
//                    .cornerRadius(25)
//                    .padding(.horizontal)
//                    .padding(.bottom, 50)
                    
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: validateAndSubmit, label: {
                            Text("Save")
                        })
                    }
                }
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                //.background(Color(UIColor.systemGray6))
                //.edgesIgnoringSafeArea(.all)
                .onDisappear{
                    userViewModel.fetchUserData { success in
                        if !success {
                            print("Error Fetching User Data after update")
                        }
                    }
                }
            }
            .presentationDetents([.fraction(0.4)])
        }
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
        } else if uid != initialUid {
            // Additional check if UID is changed and needs to be unique
            userViewModel.checkIfUIDExists(uid: uid) { exist in
                if !exist {
                    if isValid {
                        onSubmit(username, uid)
                    }
                } else {
                    // Proceed with submission if both checks pass
                    uidWarning = "Someone else has taken this UID, think about another one"
                    isValid = false
                }
            }
        }
    }
}

#Preview {
    ProfileSetupView(initialUsername: "", initialUid: "", onSubmit: {_,_ in 
        print("Submit")
    })
}
