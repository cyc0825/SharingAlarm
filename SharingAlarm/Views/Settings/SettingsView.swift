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
                Section {
                    NavigationLink(destination: ProfileView()) {
                        HStack {
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                Spacer()
                            }
                            .frame(width: 20)
                            Text("Profile")
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: IconSelectionView()) {
                        HStack {
                            HStack {
                                Image(systemName: "apps.iphone")
                                Spacer()
                            }
                            .frame(width: 20)
                            Text("Change App Icon")
                        }
                    }
                    
                    NavigationLink(destination: AppearanceSelectionView()) {
                        HStack {
                            HStack {
                                Image(systemName: "wand.and.rays")
                                Spacer()
                            }
                            .frame(width: 20)
                            Text("Change Appearance")
                        }
                    }
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
        List {
            VStack(alignment: .center) {
                Image(uiImage: AvatarGenerator.generateAvatar(for: userViewModel.appUser.name, size: CGSize(width: 100, height: 100)) ?? UIImage())
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)
                    .padding(.top, 20)
                
                // Username
                Text(userViewModel.appUser.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)
                
                // UID
                Text("@\(userViewModel.appUser.uid)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .listRowBackground(Color(UIColor.systemGroupedBackground))
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(EdgeInsets()) // Remove extra padding

            // Edit Profile Section
            Section {
                Button {
                    showingProfileEdit = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                        Text("Edit Profile")
                    }
                }
                .tint(.accent)
            }

            Section {
                EmptyView()
            }.frame(height: 20)

            // Alarm Sounds Section
            Section {
                HStack {
                    Image(systemName: "waveform")
                    NavigationLink(destination: AlarmSoundView(viewModel: alarmsViewModel, arViewModel: arViewModel)) {
                        Text("Ringtone Library")
                    }
                }
                HStack {
                    Image(systemName: "person.crop.circle.dashed.circle")
                    NavigationLink(destination: MembershipView()) {
                        Text("Membership")
                    }
                }
            }

            Section {
                EmptyView()
            }.frame(height: 20)

            // Sign Out and Delete Account Sections
            Section {
                Button(role: .cancel, action: signOut) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                        Text("Sign out")
                    }
                }
                .tint(.accent)
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
                        showingProfileEdit = false
                        UserDefaults.standard.setValue(username, forKey: "name")
                        UserDefaults.standard.setValue(uid, forKey: "uid")
                        userViewModel.appUser.uid = uid
                        userViewModel.appUser.name = username
                        userViewModel.saveUserData()
                    }
                )
            }
        .background(
            Color(UIColor.systemGroupedBackground)
        )
        .toolbar {
            ToolbarItem {
                HStack {
                    Image(systemName: "seal.fill")
                        .foregroundStyle(.accent)
                    Text("\(userViewModel.appUser.money)")
                        .foregroundStyle(.accent)
                }
                .popoverTip(EconomyTip())
            }
        }
    }
}

#Preview {
    ProfileView()
}
