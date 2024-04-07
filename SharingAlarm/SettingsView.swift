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
    @State private var showingProfileEdit = false
    
    let userName: String = UserDefaults.standard.value(forKey: "name") as? String ?? "Unknown"
    let uid: String = UserDefaults.standard.value(forKey: "uid") as? String ?? "Unknown"
    var body: some View {
        VStack(alignment: .leading) {
            // User information
            
            Text("ID: \(authViewModel.user?.uid ?? userName)")
                .font(.callout)
                .foregroundColor(.gray)
                .padding(.bottom)

            // List of options
            List {
                Section {
                    Button("Edit Profile") {
                        showingProfileEdit = true
                    }
                }
                
                Section {
                    EmptyView()
                }.frame(height: 20)
                
                Section {
//                    NavigationLink(destination: VIPLevelView()) {
//                        Text("VIP Level")
//                    }
                    NavigationLink(destination: AlarmSoundShopView()) {
                        Text("Alarm Sounds")
                    }
                }
                
                Section {
                    EmptyView()
                }.frame(height: 20)
                
                Section {
                    Button("Log out") {
                        UserDefaults.standard.setValue(false, forKey: "logged")
                        authViewModel.updateAuthenticationState(isAuthenticated: false)
                        UserDefaults.standard.removeObject(forKey: "appleIDUser")
                        UserDefaults.standard.removeObject(forKey: "name")
                        UserDefaults.standard.removeObject(forKey: "uid")
                    }
                    .foregroundColor(.red)
                    
                }
            }
            .listStyle(SidebarListStyle())
        }
        .navigationTitle(authViewModel.user?.name ?? uid)
        .padding()
        .background {
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileSetupView { username, uid in
                authViewModel.saveOrUpdateUserProfile(username: username, uid: uid) {
                    showingProfileEdit = false
                }
            }
            .environment(\.colorScheme, .light)
        }
    }
}

struct VIPLevelView: View {
    var body: some View {
        Text("VIP Level Details")
    }
}

struct AlarmSoundShopView: View {
    var body: some View {
        Text("Alarm Sound Shop")
    }
}

#Preview {
    ProfileView()
}
