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
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showingProfileEdit = false
    
    let userName: String = UserDefaults.standard.value(forKey: "name") as? String ?? "Give yourself a name so that your friend can remember you"
    let uid: String = UserDefaults.standard.value(forKey: "uid") as? String ?? "Haven't setup yet"
    @State var presentingConfirmationDialog = false
    
    private func deleteAccount() {
        Task {
            if await authViewModel.deleteAccount() == true {
                print("Successfully deleting account")
            }
        }
    }
    
    private func signOut() {
        authViewModel.signOut()
        UserDefaults.standard.setValue(false, forKey: "logged")
        UserDefaults.standard.removeObject(forKey: "appleIDUser")
        UserDefaults.standard.removeObject(forKey: "name")
        UserDefaults.standard.removeObject(forKey: "uid")
        UserDefaults.standard.removeObject(forKey: "lastAlarmFetchDate")
        UserDefaults.standard.removeObject(forKey: "lastFriendRequestFetchDate")
        UserDefaults.standard.removeObject(forKey: "userID")
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // User information
            
            Text("UID: \(uid)")
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
                  Button(role: .cancel, action: signOut) {
                    HStack {
                      Spacer()
                      Text("Sign out")
                      Spacer()
                    }
                  }
                }
                Section {
                  Button(role: .destructive, action: { presentingConfirmationDialog.toggle() }) {
                    HStack {
                      Spacer()
                      Text("Delete Account")
                      Spacer()
                    }
                  }
                }
            }
        }
        .navigationTitle(userName)
        .padding()
        .confirmationDialog("Deleting your account is permanent. Do you want to delete your account?",
                            isPresented: $presentingConfirmationDialog, titleVisibility: .visible) {
          Button("Delete Account", role: .destructive, action: deleteAccount)
          Button("Cancel", role: .cancel, action: { })
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileSetupView(
                onSubmit: { username, uid in
                    // authViewModel.createUserDocument(userID: uid, name: username, uid: uid)
                    showingProfileEdit = false
                    UserDefaults.standard.setValue(username, forKey: "name")
                    UserDefaults.standard.setValue(uid, forKey: "uid")
                    userViewModel.appUser.uid = uid
                    userViewModel.appUser.name = username
                    userViewModel.saveUserData()
                },
                initialUsername: userViewModel.appUser.name,
                initialUid: userViewModel.appUser.uid
            )
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
