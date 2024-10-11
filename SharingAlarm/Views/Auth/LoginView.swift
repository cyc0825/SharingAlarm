//
//  LoginView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import AuthenticationServices

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
        VStack {
            HStack {
                Image(systemName: "at")
                TextField("Email", text: $authViewModel.email)
                    .accentColor(.thirdAccent)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focus, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        self.focus = .password
                    }
            }
            .padding()
            .background(Capsule()
                .fill(.secondAccent.opacity(0.4)))
            
            HStack {
                Image(systemName: "lock")
                SecureField("Password", text: $authViewModel.password)
                    .accentColor(.thirdAccent)
                    .disableAutocorrection(true)
                    .focused($focus, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        signInWithEmailPassword()
                    }
            }
            .padding()
            .background(Capsule()
                .fill(.secondAccent.opacity(0.4)))
            
            if !authViewModel.errorMessage.isEmpty {
                VStack {
                    Text(authViewModel.errorMessage)
                        .foregroundColor(Color(UIColor.systemRed))
                }
            }
            
            Button(action: signInWithEmailPassword) {
                if authViewModel.authenticationState != .authenticating {
                    Text("Login")
                        .foregroundStyle(.systemText)
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
            .padding()
            .background(Capsule().fill(.secondAccent))
            .opacity(!authViewModel.isValid ? 0.5 : 1)
            
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
            .signInWithAppleButtonStyle(colorScheme == .light ? .white : .black)
            .frame(height: 50)
            .cornerRadius(25)
            Button(action: { authViewModel.switchFlow(.phoneNumberLogin) }) {
                Text("Use Phone Number")
                    .fontWeight(.semibold)
                    .foregroundColor(.secondAccent)
            }
            .padding()
            HStack {
                Text("Don't have an account yet?")
                Button(action: { authViewModel.switchFlow(.signUp) }) {
                    Text("Sign up")
                        .fontWeight(.semibold)
                        .foregroundColor(.secondAccent)
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
