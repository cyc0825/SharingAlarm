//
//  SharingAlarmApp.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import CloudKit
import EventKit

import Firebase
import FirebaseCore
import FirebaseMessaging

import UIKit
import AVFoundation

@main
struct SharingAlarmApp: App {

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var friendViewModel = FriendsViewModel()
    @StateObject private var activityViewModel = ActivitiesViewModel()
    @StateObject private var alarmViewModel = AlarmsViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
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
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var gcmMessageIDKey = "gcm.Message_ID"
    static let shared = AppDelegate()
    
    var vibrationTimer: Timer?
    var rescheduleTimer: Timer?
    
    var alarmWindow: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Request notification permissions
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            } else if granted {
                print("Notification permissions granted.")
            } else {
                print("Notification permissions denied.")
            }
        }

        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        initNotificationAction()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered for remote notifications with token: \(deviceToken)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func initNotificationAction() {
        print("initNotificationAction")
        let acceptAction = UNNotificationAction(identifier: "ACCEPT_ACTION",
              title: "Accept",
              options: [])
        let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION",
              title: "Decline",
              options: [])
        // Define the notification type
        let alarmInviteCategory =
              UNNotificationCategory(identifier: "alarm",
              actions: [acceptAction, declineAction],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([alarmInviteCategory])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["fcmToken": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        if let userId = Auth.auth().currentUser?.uid {
            updateUserToken(userId, fcmToken ?? "")
        } else {
            // Save the token locally if user is not logged in
            UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        }
    }
    
    func updateUserToken(_ userId: String, _ token: String) {
        let db = Firestore.firestore()
        db.collection("UserData").document(userId).setData(["fcmToken": token], merge: true) { error in
            if let error = error {
                print("Error updating FCM token: \(error)")
            } else {
                print("FCM token updated successfully")
            }
        }
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification will present")
        let userInfo = notification.request.content.userInfo
        if userInfo.isEmpty {
            self.startLongVibration()
        } else {
            handleNotification(userInfo: userInfo)
        }
        completionHandler([.banner, .sound])
    }

    // Handle notification when app is in the background or closed
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("UNNotificationResponse did Receive")
        let userInfo = response.notification.request.content.userInfo
        
        if response.notification.request.content.categoryIdentifier == "alarm" {
            switch response.actionIdentifier {
            case "ACCEPT_ACTION":
                handleNotification(userInfo: userInfo)
                break
                
            case "DECLINE_ACTION":
                print("User declined")
                break
                
            case UNNotificationDefaultActionIdentifier,
            UNNotificationDismissActionIdentifier:
                print("User dismissed")
                break
                
            default:
                break
            }
        } else {
            presentAlarmView(title: "Alarm Notification", body: "You have an new alarm", alarmTime: Date(), sound: "Harmony.mp3")
        }
        completionHandler()
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
    -> UIBackgroundFetchResult {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
        handleNotification(userInfo: userInfo)
        
        return UIBackgroundFetchResult.newData
    }

    private func handleNotification(userInfo: [AnyHashable: Any]) {
        print("Received data message: \(userInfo)")
        if let title = userInfo["title"] as? String,
           let body = userInfo["body"] as? String,
           let alarmTimeString = userInfo["alarmTime"] as? String,
           let sound = userInfo["sound"] as? String {
           
            print("alarmTimeString: \(alarmTimeString)")

            // Date formatter configuration
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let alarmTime = dateFormatter.date(from: alarmTimeString) {
                // Debug information for parsed date
                print("Parsed alarmTime: \(alarmTime)")
                
                print("Schedule an Alarm at \(alarmTime)")
                scheduleLocalNotification(title: title, body: body, alarmTime: alarmTime, sound: sound)
            } else {
                // Debug information for date parsing failure
                print("Failed to parse alarmTimeString: \(alarmTimeString)")
            }
        } else {
            print("This might be an Alarm")
        }
    }
    
    private func presentAlarmView(title: String, body: String, alarmTime: Date, sound: String) {
            // Debug statement to verify function call
            print("Presenting AlarmView with title: \(title), body: \(body), alarmTime: \(alarmTime), sound: \(sound)")

            // Create a window and set the root view controller to your custom SwiftUI view
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let window = UIWindow(windowScene: scene)
                let rootView = AlarmView(title: title, alarmBody: body, alarmTime: alarmTime, sound: sound, onClose: {
                    window.isHidden = true
                    window.rootViewController = nil
                    self.alarmWindow = nil
                    // Handle alarm close action
                    print("Alarm closed")
                }, onSnooze: {
                    window.isHidden = true
                    window.rootViewController = nil
                    self.alarmWindow = nil
                    // Reschedule the alarm for 10 minutes later
                    let snoozeTime = alarmTime.addingTimeInterval(600) // 10 minutes later
                    self.scheduleLocalNotification(title: title, body: body, alarmTime: snoozeTime, sound: sound)
                    print("Alarm snoozed for 10 minutes")
                })
                window.rootViewController = UIHostingController(rootView: rootView)
                window.makeKeyAndVisible()
                self.alarmWindow = window

                // Vibration
            } else {
                print("No suitable window scene found.")
            }
        }
    
    private func scheduleLocalNotification(title: String, body: String, alarmTime: Date, sound: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: alarmTime), repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error)")
            } else {
                print("Local notification scheduled.")
            }
        }
    }
    
}

extension AppDelegate {
    func startLongVibration() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        vibrationTimer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(vibrate), userInfo: nil, repeats: true)
        rescheduleTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(stopVibrationAndReschedule), userInfo: nil, repeats: false)
    }

    @objc private func stopVibrationAndReschedule() {
        stopVibration()
        // rescheduleAlarm()
    }
    
    @objc private func vibrate() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    func stopVibration() {
        DispatchQueue.main.async {
            if let vibrationTimer = self.vibrationTimer {
                vibrationTimer.invalidate()
            } else {
                print("vibrationTimer not exist")
            }
            self.vibrationTimer = nil
        }
    }
}
