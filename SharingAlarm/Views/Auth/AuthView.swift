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
    }
}

struct AuthenticationView_Previews: PreviewProvider {
  static var previews: some View {
    AuthView()
      .environmentObject(AuthViewModel())
  }
}
