//
//  SettingsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ProfileView()) {
                    Text("Profile")
                }
                
                Button("Change App Icon") {
                    changeAppIcon(to: "AlternateIconName") // Specify your alternate icon's file name
                }
            }
                .navigationTitle("Settings")
        }
    }
    
    func changeAppIcon(to iconName: String?) {
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let error = error {
                    print("Error changing app icon: \(error.localizedDescription)")
                } else {
                    print("App icon changed successfully")
                }
            }
        }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Assuming you have this for authentication
    var body: some View {
        VStack(spacing: 20) {
            Text("Username: \(UserDefaults.standard.value(forKey: "name") as? String ?? "Unknown")")
            Text("Apple ID: \(UserDefaults.standard.value(forKey: "email") as? String ?? "Unknown")")
            Button("Log Out") {
                UserDefaults.standard.setValue(false, forKey: "logged")
                authViewModel.updateAuthenticationState(isAuthenticated: false)
                UserDefaults.standard.removeObject(forKey: "appleIDUser")
                UserDefaults.standard.removeObject(forKey: "name")
                UserDefaults.standard.removeObject(forKey: "email")
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .navigationTitle("Profile")
    }
}

#Preview {
    SettingsView()
}
