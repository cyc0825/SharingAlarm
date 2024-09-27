//
//  SettingsView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: ProfileView()) {
                        HStack {
                            HStack {
                                Image(systemName: "person")
                                    .foregroundStyle(.accent)
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
                                    .foregroundStyle(.accent)
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
                                    .foregroundStyle(.accent)
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
                                    .foregroundStyle(.accent)
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
                                    .foregroundStyle(.accent)
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
                                    .foregroundStyle(.accent)
                                Spacer()
                            }
                            .frame(width: 20)
                            Text("Notification Settings")
                        }
                        .foregroundStyle(Color.systemText)
                    }
                }
                
                Section {
                    ShareLink (item: URL(string: "https://testflight.apple.com/join/HraW4tkJ")!) {
                        HStack {
                            Image(systemName: "figure.wave")
                            Text("Recommend this app to Friends!")
                                .foregroundStyle(Color.systemText)
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
                if UserDefaults.standard.bool(forKey: "isPremium")  {
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
                            .foregroundStyle(.systemText)
                    }
                }
                .tint(.accent)
                NavigationLink(destination: DeleteProfileView()) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundStyle(.accent)
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
                        .foregroundStyle(.accent)
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
                            .foregroundStyle(.systemText)
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
                    userViewModel.updateUserData(updates: [
                        "name": username,
                        "uid": uid
                    ])
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
