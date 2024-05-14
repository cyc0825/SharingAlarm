//
//  SharingAlarmApp.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import CloudKit
import EventKit

import FirebaseCore

import PushKit
import UIKit
import CallKit

@main
struct SharingAlarmApp: App {

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var friendViewModel = FriendsViewModel()
    @StateObject private var activityViewModel = ActivitiesViewModel()
    @StateObject private var alarmViewModel = AlarmsViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        requestNotificationPermission()
        subscribeToFriendRequests()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                AuthedView {
                } content: {
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(userViewModel)
                        .environmentObject(friendViewModel)
                        .environmentObject(activityViewModel)
                        .environmentObject(alarmViewModel)
                    Spacer()
                }
            }
        }
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

func scheduleNotification(for alarm: Alarm, viewModel: AlarmsViewModel) {
    let content = UNMutableNotificationContent()
    content.title = "Alarm"
    content.body = "Your alarm is going off!"
    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "AlarmTest.mp3"))
    
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
            // Now update the CloudKit record
            print("Scheduled notification, now updateCloudKitRecord")
            updateCloudKitRecord(for: updatedAlarm, viewModel: viewModel)
            
        }
    }
}

func modifyNotification(for alarm: Alarm, viewModel: AlarmsViewModel) {
    guard let identifier = alarm.notificationIdentifier else {
        return
    }
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    viewModel.removeAlarm(recordID: alarm.recordID) { result in
        switch result {
        case .success():
            scheduleNotification(for: alarm, viewModel: viewModel)
        case .failure(let error):
            print("Error removing alarm record: \(error.localizedDescription)")
        }
    }
}

func updateCloudKitRecord(for alarm: Alarm, viewModel: AlarmsViewModel) {
    let record = alarm.toCKRecord()
    let database = CKContainer.default().publicCloudDatabase
    database.save(record) { savedRecord, error in
        if let error = error {
            print("Error updating CloudKit record: \(error.localizedDescription)")
        } else if let savedRecord = savedRecord {
            print("Successfully updated CloudKit record with notification identifier.")
            DispatchQueue.main.sync{
                viewModel.alarms.append(alarm)
            }
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, PKPushRegistryDelegate {
    
    @StateObject var alarmViewModel = AlarmsViewModel()
    @StateObject var viewModel = FriendsViewModel()
    static let shared = AppDelegate()
    
    var voipRegistry: PKPushRegistry!
    var callManager: CallManager!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("Permission granted: \(granted)")
        }
        UNUserNotificationCenter.current().delegate = self
        setupPushKit()
        callManager = CallManager()
        FirebaseApp.configure()
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
//            viewModel.searchRequest()
        }

        completionHandler(.newData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification will present: \(notification.request.identifier)")
        alarmViewModel.startLongVibration()
        completionHandler([.banner, .sound, .badge]) // Decide how to present the notification in the foreground.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: NSNotification.Name("NotificationTapped"), object: nil)
        completionHandler()
    }
    
    func setupPushKit() {
            voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
            voipRegistry.delegate = self
            voipRegistry.desiredPushTypes = [.voIP]
        }

    // MARK: - PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        // Process the received push credentials and send them to your server
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        // Assume you decode your incoming push and determine it's an incoming call
        let uuid = UUID()
        let phoneNumber = "1234567890" // Example phone number
        callManager.reportIncomingCall(uuid: uuid, phoneNumber: phoneNumber)
        completion()
    }
}
