//
//  ContentView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendViewModel: FriendsViewModel
    @EnvironmentObject var activityViewModel: ActivitiesViewModel
    @State private var loaded = false
    @State private var showingAlarmView = false
    var userAppleId = UserDefaults.standard.value(forKey: "appleIDUser") as! String

    var body: some View {
        ZStack {
            TabView {
                AlarmsView()
                    .tabItem {
                        Label("Alarms", systemImage: "alarm.fill")
                    }
                
                ActivitiesView()
                    .tabItem {
                        Label("Activities", systemImage: "list.bullet.rectangle")
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
                if !loaded {
                    authViewModel.checkUserExistsWithAppleID(appleID: userAppleId)
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                        friendViewModel.searchRequest()
                        friendViewModel.fetchFriends()
                        activityViewModel.fetchActivity()
                    }
                    loaded = true
                }
            }
            .sheet(isPresented: $authViewModel.shouldShowProfileSetup) {
                ProfileSetupView(
                    onSubmit: { username, uid in
                    authViewModel.saveOrUpdateUserProfile(username: username, uid: uid) {
                        authViewModel.setUserExists(true)
                        authViewModel.shouldShowProfileSetup = false
                        }
                    },
                    initialUsername: "",
                    initialUid: "")
                .environment(\.colorScheme, .light)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NotificationTapped"))) { _ in
                showingAlarmView = true
            }
            .sheet(isPresented: $showingAlarmView) {
                AlarmView()
            }
        }
//        NavigationView {
//            Text("Welcome")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: logout) {
//                        Text("Log out")
//                    }
//                }
//            }
//            Text("Select an item")
//        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

