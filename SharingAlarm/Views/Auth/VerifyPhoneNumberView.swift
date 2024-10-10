//
//  VerifyPhoneNumberView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/10/9.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

private enum FocusableField: Hashable {
  case phoneNumber
  case code
}

struct VerifyPhoneNumberView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FocusState private var focus: FocusableField?
    
    private func signInWithPhoneNumber() {
        Task {
            if await authViewModel.signInWithPhoneNumber() == true {
                dismiss()
            }
        }
    }
    
    private func sentVerificationCode(phoneNumber: String) {
        print("Send verification code to \(phoneNumber)")
        PhoneAuthProvider.provider()
          .verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
              if let error = error {
                print(error.localizedDescription)
                return
              }
              // Sign in using the verificationID and the code sent to the user
              // ...
              UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
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
                        Image(systemName: "phone")
                        Text("(+1)")
                        TextField("PhoneNumber", text: $authViewModel.phoneNumber)
                            .accentColor(.thirdAccent)
                            .textInputAutocapitalization(.never)
                            .textContentType(.telephoneNumber)
                            .disableAutocorrection(true)
                            .focused($focus, equals: .phoneNumber)
                            .submitLabel(.next)
                            .onSubmit {
                                self.focus = .code
                            }
                        Button {
                            sentVerificationCode(phoneNumber: "+1\(authViewModel.phoneNumber)")
                        } label: {
                            Text("send")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.secondAccent)
                    }
                    .padding(.vertical, 6)
                    .background(Divider(), alignment: .bottom)
                    .padding(.bottom, 4)
                    
                    HStack {
                        Image(systemName: "number")
                        SecureField("Code", text: $authViewModel.code)
                            .accentColor(.thirdAccent)
                            .disableAutocorrection(true)
                            .textContentType(.oneTimeCode)
                            .focused($focus, equals: .code)
                            .submitLabel(.go)
                            .onSubmit {
                                signInWithPhoneNumber()
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
                    
                    Button(action: signInWithPhoneNumber) {
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
                    .tint(authViewModel.isValid ? .secondAccent : .gray)
                    
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
                        Text("Try Account login?")
                        Button(action: { authViewModel.switchFlow(.login) }) {
                            Text("Switch to account login")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding([.top, .bottom], 50)
                }
                .padding()
            }
        }
        
    }
}
