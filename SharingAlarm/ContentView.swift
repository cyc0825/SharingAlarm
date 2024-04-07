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
    @State private var loaded = false
    var userAppleId = UserDefaults.standard.value(forKey: "appleIDUser") as! String

    var body: some View {
        ZStack {
            TabView {
                AlarmsView()
                    .tabItem {
                        Label("Alarms", systemImage: "alarm.fill")
                    }
                    .background {
                        Color(UIColor.secondarySystemBackground)
                            .ignoresSafeArea()
                    }
                
                LogsView()
                    .tabItem {
                        Label("Logs", systemImage: "list.bullet.rectangle")
                    }
                    .background {
                        Color(UIColor.secondarySystemBackground)
                            .ignoresSafeArea()
                    }
                
                FriendsView()
                    .tabItem {
                        Label("Friends", systemImage: "person.3.fill")
                    }
                    .background {
                        Color(UIColor.secondarySystemBackground)
                            .ignoresSafeArea()
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .background {
                        Color(UIColor.secondarySystemBackground)
                            .ignoresSafeArea()
                    }
            }
            .onAppear {
                if !loaded {
                    authViewModel.checkUserExistsWithAppleID(appleID: userAppleId)
                    loaded = true
                }
            }
            .sheet(isPresented: $authViewModel.shouldShowProfileSetup) {
                ProfileSetupView { username, uid in
                    authViewModel.saveOrUpdateUserProfile(username: username, uid: uid) {
                        authViewModel.setUserExists(true)
                        authViewModel.shouldShowProfileSetup = false
                    }
                }
                .environment(\.colorScheme, .light)
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

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
