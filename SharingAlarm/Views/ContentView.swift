//
//  ContentView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import TipKit
import CoreData

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendViewModel: FriendsViewModel
    @EnvironmentObject var groupsViewModel: GroupsViewModel
    @EnvironmentObject var alarmsViewModel: AlarmsViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var arViewModel: AudioRecorderViewModel
    @State private var showingEditProfile = false
    // var userAppleId = UserDefaults.standard.value(forKey: "appleIDUser") as! String
    
    var body: some View {
        ZStack {
            TabView {
                AlarmsView()
                    .tabItem {
                        Label("Alarms", systemImage: "alarm.fill")
                    }
                
                GroupsView()
                    .tabItem {
                        Label("Groups", systemImage: "list.bullet.rectangle")
                    }
                
                FriendsView()
                    .tabItem {
                        Label("Friends", systemImage: "person.3.fill")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .onAppear {
                userViewModel.fetchUserData { success in
                    if !success {
                        showingEditProfile = true
                    }
                }
                alarmsViewModel.startListeningAlarms()
                EconomyViewModel.shared.listenForTransactions()
//                    friendViewModel.fetchFriends()
//                    friendViewModel.fetchOwnRequest()
//                    friendViewModel.fetchFriendsRequest()
//                    groupsViewModel.fetchGroup()
                arViewModel.loadLocalRecording() { exist in
                    if exist {
                        alarmsViewModel.personalizedSounds.append("YourRecording")
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                ProfileSetupView(
                    initialUsername: "",
                    initialUid: "",
                    onSubmit: { username, uid in
                        authViewModel.createUserDocument(userID: authViewModel.user?.uid ?? uid, name: username, uid: uid)
                        userViewModel.fetchUserData { success in
                            if success {
                                authViewModel.isNewUser = false
                                showingEditProfile = false
                                alarmsViewModel.fetchRingtoneList()
                                if let userId = authViewModel.user?.uid {
                                    userViewModel.updateFCMTokenIfNeeded(userId: userId)
                                }
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $friendViewModel.showScanResult) {
                if let scanResult = friendViewModel.scanResult {
                    QRScanResultView(friendViewModel: friendViewModel, user2ID: scanResult)
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

