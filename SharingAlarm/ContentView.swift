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
        TabView {
            AlarmsView()
                .tabItem {
                    Label("Alarms", systemImage: "alarm.fill")
                }

            LogsView()
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.rectangle")
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
                loaded = true
            }
        }
        .sheet(isPresented: $authViewModel.shouldShowProfileSetup) {
            ProfileSetupView { username, email in
                saveUserProfileToCloudKit(username: username, email: email) {
                    authViewModel.setUserExists(true)
                }
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
    
    private func logout(){
        UserDefaults.standard.setValue(false, forKey: "logged")
        authViewModel.updateAuthenticationState(isAuthenticated: false)
        UserDefaults.standard.removeObject(forKey: "appleIDUser")
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
