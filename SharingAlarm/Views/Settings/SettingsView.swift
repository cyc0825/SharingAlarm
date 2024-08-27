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
                
                NavigationLink(destination: IconSelectionView()) {
                    Text("Change App Icon")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var alarmsViewModel: AlarmsViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var arViewModel: AudioRecorderViewModel
    @State private var showingProfileEdit = false
    
    @State var userName: String = UserDefaults.standard.value(forKey: "name") as? String ?? "Give yourself a name so that your friend can remember you"
    @State var Uid: String = UserDefaults.standard.value(forKey: "uid") as? String ?? "Haven't setup yet"
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
        VStack(alignment: .center) {
            Image(uiImage: AvatarGenerator.generateAvatar(for: userName, size: CGSize(width: 100, height: 100)) ?? UIImage())
                .resizable()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 5)
            
            // Username
            Text(userName)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 10)
            
            // UID
            Text("@\(Uid)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // List of options
            List {
                Section(header: EmptyView()) {}
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
                    NavigationLink(destination: AlarmSoundView(viewModel: alarmsViewModel, userViewModel: userViewModel, arViewModel: arViewModel)) {
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
            .confirmationDialog("Deleting your account is permanent. Do you want to delete your account?",
                                isPresented: $presentingConfirmationDialog, titleVisibility: .visible) {
              Button("Delete Account", role: .destructive, action: deleteAccount)
              Button("Cancel", role: .cancel, action: { })
            }
            .sheet(isPresented: $showingProfileEdit) {
                ProfileSetupView(
                    initialUsername: userViewModel.appUser.name,
                    initialUid: userViewModel.appUser.uid,
                    onSubmit: { username, uid in
                        // authViewModel.createUserDocument(userID: uid, name: username, uid: uid)
                        showingProfileEdit = false
                        UserDefaults.standard.setValue(username, forKey: "name")
                        UserDefaults.standard.setValue(uid, forKey: "uid")
                        userViewModel.appUser.uid = uid
                        userViewModel.appUser.name = username
                        userName = username
                        Uid = uid
                        userViewModel.saveUserData()
                    }
                )
            }
        }
        .background(
            Color(UIColor.systemGroupedBackground)
        )
    }
}

struct VIPLevelView: View {
    var body: some View {
        Text("VIP Level Details")
    }
}

#Preview {
    ProfileView()
}
