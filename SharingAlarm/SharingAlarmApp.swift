//
//  SharingAlarmApp.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import CloudKit

import UIKit
import TipKit
import ActivityKit
import AuthenticationServices

@main
struct SharingAlarmApp: App {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("selectedAppearance") private var selectedAppearance: AppearanceOption = .system
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var friendViewModel = FriendsViewModel()
    @StateObject private var groupViewModel = GroupsViewModel()
    @StateObject private var alarmsViewModel = AlarmsViewModel()
    @StateObject private var arViewModel = AudioRecorderViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var showLaunchScreen = true
    
    init() {
        if #available(iOS 17.0, *) {
            try? Tips.configure()
        } else {
            // Fallback on earlier versions
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if showLaunchScreen {
                LaunchScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut) {
                                showLaunchScreen = false
                            }
                        }
                        appDelegate.alarmsViewModel = alarmsViewModel
                        appDelegate.userViewModel = userViewModel
                        appDelegate.friendViewModel = friendViewModel
                        
                    }
            } else if authViewModel.authenticationState == .authenticated {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(userViewModel)
                    .environmentObject(friendViewModel)
                    .environmentObject(groupViewModel)
                    .environmentObject(alarmsViewModel)
                    .environmentObject(arViewModel)
                    .onReceive(NotificationCenter.default.publisher(for: ASAuthorizationAppleIDProvider.credentialRevokedNotification)) { event in
                        authViewModel.signOut()
                        if let userInfo = event.userInfo, let info = userInfo["info"] {
                            print(info)
                        }
                    }
                    .onAppear {
                        friendViewModel.fetchFriends()
                        friendViewModel.fetchOwnRequest()
                        friendViewModel.fetchFriendsRequest()
                        groupViewModel.fetchGroup()
                        alarmsViewModel.fetchRingtoneList()
                    }
                    .preferredColorScheme(selectedAppearance.colorScheme)
                    .onOpenURL { (url) in
                        let urlString = url.absoluteString
                        print(urlString)
                        if urlString.contains("addFriend") {
                            print("QR code redirected to FR")
                            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                               let queryItems = components.queryItems {
                                for item in queryItems {
                                    if item.name == "uid", let uid = item.value {
                                        // Navigate to the Add Friend page with the uid
                                        friendViewModel.showScanResult = true
                                        friendViewModel.scanResult = uid
                                    }
                                }
                            }
                        }
                    }
            } else {
                AuthedView {
                } content: {
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(userViewModel)
                        .environmentObject(friendViewModel)
                        .environmentObject(groupViewModel)
                        .environmentObject(alarmsViewModel)
                        .environmentObject(arViewModel)
                        .onAppear {
                            friendViewModel.fetchFriends()
                            friendViewModel.fetchOwnRequest()
                            friendViewModel.fetchFriendsRequest()
                            groupViewModel.fetchGroup()
                            alarmsViewModel.fetchRingtoneList()
                        }
                        .preferredColorScheme(selectedAppearance.colorScheme)
                        .onOpenURL { (url) in
                            let urlString = url.absoluteString
                            print(urlString)
                            if urlString.contains("addFriend") {
                                print("QR code redirected to FR")
                                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                                   let queryItems = components.queryItems {
                                    for item in queryItems {
                                        if item.name == "uid", let uid = item.value {
                                            // Navigate to the Add Friend page with the uid
                                            friendViewModel.showScanResult = true
                                            friendViewModel.scanResult = uid
                                        }
                                    }
                                }
                            }
                        }
                    Spacer()
                }
                .onAppear {
                    appDelegate.alarmsViewModel = alarmsViewModel
                }
                .preferredColorScheme(selectedAppearance.colorScheme)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                print("Enter Background")
            } else if phase == .active {
                let userDefaults = UserDefaults(suiteName: "group.com.cyc0825.SharingAlarm")
                print("Become Active. Set VoiceKey to 1")
                userDefaults?.set(1, forKey: "VoiceKey")
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            } else if phase == .inactive {
                print("Become inActive")
            }
        }
    }
}

func scheduleNotification(for alarm: Alarm, viewModel: AlarmsViewModel) {
    let content = UNMutableNotificationContent()
    content.title = "Alarm"
    content.body = "Your alarm is going off!"
    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "Classic.caf"))
    
    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.time)
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
    
    let identifier = alarm.notificationIdentifier ?? UUID().uuidString
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling notification: \(error.localizedDescription)")
        } else {
            var updatedAlarm = alarm
            updatedAlarm.notificationIdentifier = identifier
        }
    }
}



extension FileManager {
    public func soundsLibraryURL(for filename: String) throws -> URL {
        let libraryURL = try url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let soundFolderURL = libraryURL.appendingPathComponent("Sounds", isDirectory: true)
        if !fileExists(atPath: soundFolderURL.path) {
            try createDirectory(at: soundFolderURL, withIntermediateDirectories: true)
        }
        return soundFolderURL.appendingPathComponent(filename, isDirectory: false)
    }
}
