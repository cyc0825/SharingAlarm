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
