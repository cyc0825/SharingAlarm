//
//  LoginView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import AuthenticationServices
import CloudKit

private enum FocusableField: Hashable {
  case email
  case password
}

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FocusState private var focus: FocusableField?
    
    private func signInWithEmailPassword() {
        Task {
            if await authViewModel.signInWithEmailPassword() == true {
                dismiss()
            }
        }
    }
    
    var body: some View {
        NavigationStack{
            ZStack {
                Color.accentColor.ignoresSafeArea(edges: .all)
                VStack{
                    Text("WELCOME!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.top, .bottom], 50)
                    Image("loginscreen")
                        .resizable()
                        .frame(width: 300, height: 300)
                        .padding(.bottom, 40)
                        .onTapGesture {
                            focus = nil
                        }
                    
                    HStack {
                        Image(systemName: "at")
                        TextField("Email", text: $authViewModel.email)
                            .accentColor(.gray)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .focused($focus, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                self.focus = .password
                            }
                    }
                    .padding(.vertical, 6)
                    .background(Divider(), alignment: .bottom)
                    .padding(.bottom, 4)
                    
                    HStack {
                        Image(systemName: "lock")
                        SecureField("Password", text: $authViewModel.password)
                            .accentColor(.gray)
                            .disableAutocorrection(true)
                            .focused($focus, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                signInWithEmailPassword()
                            }
                    }
                    .padding(.vertical, 6)
                    .background(Divider(), alignment: .bottom)
                    .padding(.bottom, 8)
                    
                    if !authViewModel.errorMessage.isEmpty {
                        VStack {
                            Text(authViewModel.errorMessage)
                                .foregroundColor(Color(UIColor.systemRed))
                        }
                    }
                    
                    Button(action: signInWithEmailPassword) {
                        if authViewModel.authenticationState != .authenticating {
                            Text("Login")
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                        else {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!authViewModel.isValid)
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .tint(authViewModel.isValid ? .thirdAccent : .gray)
                    
                    HStack {
                        VStack { Divider() }
                        Text("or")
                        VStack { Divider() }
                    }
                    
                    SignInWithAppleButton(.signIn) { request in
                        authViewModel.handleSignInWithAppleRequest(request)
                    } onCompletion: { result in
                        authViewModel.handleSignInWithAppleCompletion(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                    .frame(height: 50)
                    .cornerRadius(8)
                    
                    HStack {
                        Text("Don't have an account yet?")
                        Button(action: { authViewModel.switchFlow() }) {
                            Text("Sign up")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding([.top, .bottom], 50)
                }
                .padding()
            }
            .sheet(isPresented: $authViewModel.isNewUser) {
                ProfileSetupView(
                    onSubmit: { username, uid in
                        authViewModel.createUserDocument(userID: uid, name: username, uid: uid)
                        authViewModel.isNewUser = false
                        UserDefaults.standard.setValue(username, forKey: "name")
                        UserDefaults.standard.setValue(uid, forKey: "uid")
                    },
                    initialUsername: "",
                    initialUid: ""
                )
            }
        }
        
    }
}

struct ProfileSetupView: View {
    var onSubmit: (String, String) -> Void
    var initialUsername: String
    var initialUid: String
        
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var username: String = ""
    @State private var uid: String = ""
    @State private var isChecking = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var usernameWarning: String?
    @State private var uidWarning: String?
    
    init(onSubmit: @escaping (String, String) -> Void, initialUsername: String, initialUid: String) {
        self.onSubmit = onSubmit
        self.initialUsername = initialUsername
        self.initialUid = initialUid
        _username = State(initialValue: initialUsername)
        _uid = State(initialValue: initialUid)
    }
    
//    func isUniqueIdentifier(_ identifier: String, completion: @escaping (Bool) -> Void) {
//        let predicate = NSPredicate(format: "uid == %@", identifier)
//        let query = CKQuery(recordType: "UserData", predicate: predicate)
//        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
//            DispatchQueue.main.async {
//                if let records = records, !records.isEmpty {
//                    // Identifier exists, hence not unique
//                    completion(false)
//                } else {
//                    // No existing record with the identifier, hence unique
//                    completion(true)
//                }
//            }
//        }
//    }
    
    var body: some View {
        VStack {
            // Welcome Text at the top
            Text("Hi, enter your name and your unique identifier to let your friends find you!")
                .font(.title)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 50)
            
            Spacer()
            
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
            
            Spacer()
            Button(action: validateAndSubmit, label: {
                Text("Go")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
            })
            .background(Color.blue)
            .cornerRadius(25)
            .padding(.horizontal)
            .padding(.bottom, 50)
            
        }
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.all)
        .onDisappear{
            userViewModel.fetchUserData()
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
//            authViewModel.checkIfUIDExists(uid: uid) { exist, error in
//                guard error == nil else { print("Error"); return }
//                if !exist {
//                    if isValid {
//                        onSubmit(username, uid)
//                    }
//                } else {
//                    // Proceed with submission if both checks pass
//                    uidWarning = "Someone else has taken this UID, think about another one"
//                    isValid = false
//                }
//            }
            onSubmit(username, uid)
        } else {
            print("UID Unchanged")
            // UID not changed, proceed if username check passes
            if isValid {
                onSubmit(username, uid)
            }
        }
    }
}
