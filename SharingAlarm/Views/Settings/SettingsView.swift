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
                                Image(systemName: "person")
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
                    
                    NavigationLink(destination: FeedbackView()) {
                        HStack {
                            HStack {
                                Image(systemName: "message")
                                Spacer()
                            }
                            .frame(width: 20)
                            Text("Provide Feedback")
                        }
                    }
                }
                Section {
                    Button {
                        if let url = URL(string:UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    } label: {
                        HStack {
                            HStack {
                                Image(systemName: "gear")
                                Spacer()
                            }
                            .frame(width: 20)
                            Text("System Configuration")
                        }
                        .foregroundStyle(Color.systemText)
                    }
                    
                    Button {
                        if let url = URL(string:UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    } label: {
                        HStack {
                            HStack {
                                Image(systemName: "bell")
                                Spacer()
                            }
                            .frame(width: 20)
                            Text("Notification Settings")
                        }
                        .foregroundStyle(Color.systemText)
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
    @State private var showingPremiumStore = false
    
    private func signOut() {
        authViewModel.signOut()
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
        UserDefaults.standard.setValue(false, forKey: "logged")
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
                if userViewModel.appUser.subscription != nil {
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "star.circle.fill")
                            Text("Premium")
                                .font(.subheadline)
                        }
                        .foregroundColor(.systemText)
                    }
                    .buttonStyle(.borderedProminent)
                }
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
                NavigationLink(destination: DeleteProfileView()) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Profile")
                    }
                }
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
                Button {
                    showingPremiumStore = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.dashed.circle")
                        Text("Membership")
                        Spacer()
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
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileSetupView(
                initialUsername: userViewModel.appUser.name,
                initialUid: userViewModel.appUser.uid,
                onSubmit: { username, uid in
                    userViewModel.saveUserData(username: username, uid: uid)
                    userViewModel.fetchUserData { success in
                        if success {
                            showingProfileEdit = false
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showingPremiumStore) {
            PremiumStoreView()
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
    SettingsView()
}
