//
//  SharingAlarmApp.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import CloudKit
import UserNotifications
import EventKit

@main
struct SharingAlarmApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        requestNotificationPermission()
        customizeTabBarAppearance()
        subscribeToFriendRequests()
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
                    .environment(\.colorScheme, .light)
            } else {
                LoginView(authViewModel: authViewModel)
                    .environmentObject(authViewModel)
                    .environment(\.colorScheme, .light)
            }
        }
    }
    
    func customizeTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.7)
    
        UITabBar.appearance().standardAppearance = appearance
        // Use this line if you want the same appearance when the tab bar scrolls (iOS 15+)
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
            print("Notification permission granted.")
        } else if let error = error {
            print("Notification permission error: \(error.localizedDescription)")
        }
    }
}

func subscribeToFriendRequests() {
    let predicate = NSPredicate(value: true) // Subscribe to all changes
    let subscription = CKQuerySubscription(recordType: "FriendRequest",
                                           predicate: predicate,
                                           subscriptionID: "friend-request-changes",
                                           options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])

    let info = CKSubscription.NotificationInfo()
    info.alertBody = "There's an update to your friend requests!"
    info.shouldBadge = true
    info.soundName = "default"
    subscription.notificationInfo = info

    CKContainer.default().publicCloudDatabase.save(subscription) { subscription, error in
        if let error = error {
            print("Subscription failed: \(error.localizedDescription)")
        } else {
            print("Subscription successful")
        }
    }
}

func scheduleNotification(for alarm: Alarm) {
    let content = UNMutableNotificationContent()
    content.title = "Alarm"
    content.body = "Your alarm is going off!"
    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "AlarmTest.mp3"))
    
    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.time)
    print(triggerDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
    
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling notification: \(error.localizedDescription)")
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @StateObject var viewModel = FriendsViewModel()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("Permission granted: \(granted)")
        }
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered for remote notifications with token: \(deviceToken)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let dict = userInfo as! [String: NSObject]
        let notification = CKNotification(fromRemoteNotificationDictionary: dict)

        if notification?.subscriptionID == "friend-request-changes" {
            print("detect changed for friend request")
            viewModel.searchRequest()
        }

        completionHandler(.newData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification will present: \(notification.request.identifier)")
        completionHandler([.banner, .sound, .badge]) // Decide how to present the notification in the foreground.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: NSNotification.Name("NotificationTapped"), object: nil)
        completionHandler()
    }
}
