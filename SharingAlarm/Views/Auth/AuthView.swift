//
//  AuthView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/28.
//

import SwiftUI
import Combine

struct AuthView: View {
    @EnvironmentObject var authviewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea(edges: .all)
            VStack{
                VStack {
                    Text("WELCOME!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 30)
                    Image("loginscreen")
                        .resizable()
                        .frame(width: 300, height: 300)
                }
                .padding()
                .onTapGesture {
                    self.dismissKeyboard()
                }
                VStack {
                    switch authviewModel.flow {
                    case .login:
                        LoginView()
                            .environmentObject(authviewModel)
                    case .phoneNumberLogin:
                        VerifyPhoneNumberView()
                            .environmentObject(authviewModel)
                    case .signUp:
                        SignupView()
                            .environmentObject(authviewModel)
                    }
                }
                .frame(maxHeight: 300) // Fixes the height of the changing content
                .padding([.top, .horizontal])
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
