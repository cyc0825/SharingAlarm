//
//  AuthedView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/28.
//

import SwiftUI
import AuthenticationServices

extension AuthedView where Unauthenticated == EmptyView {
  init(@ViewBuilder content: @escaping () -> Content) {
    self.unauthenticated = nil
    self.content = content
  }
}

struct AuthedView<Content, Unauthenticated>: View where Content: View, Unauthenticated: View {
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @State private var presentingLoginScreen = false
    @State private var presentingProfileScreen = false
    
    var unauthenticated: Unauthenticated?
    @ViewBuilder var content: () -> Content
    
    public init(unauthenticated: Unauthenticated?, @ViewBuilder content: @escaping () -> Content) {
        self.unauthenticated = unauthenticated
        self.content = content
    }
    
    public init(@ViewBuilder unauthenticated: @escaping () -> Unauthenticated, @ViewBuilder content: @escaping () -> Content) {
        self.unauthenticated = unauthenticated()
        self.content = content
    }
    
    
    var body: some View {
        switch viewModel.authenticationState {
        case .unauthenticated, .authenticating:
            AuthView()
                .environmentObject(viewModel)
        case .authenticated:
            content()
                .onReceive(NotificationCenter.default.publisher(for: ASAuthorizationAppleIDProvider.credentialRevokedNotification)) { event in
                    viewModel.signOut()
                    if let userInfo = event.userInfo, let info = userInfo["info"] {
                        print(info)
                    }
                }
                .sheet(isPresented: $presentingProfileScreen) {
                    NavigationView {
                        ProfileView()
                            .environmentObject(viewModel)
                    }
                }
        }
    }
}
