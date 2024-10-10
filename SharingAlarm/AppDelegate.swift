//
//  SceneDelegate.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/10/6.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseMessaging
import AVFoundation
import ActivityKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var gcmMessageIDKey = "gcm.Message_ID"
    static let shared = AppDelegate()
    
    var vibrationTimer: Timer?
    var rescheduleTimer: Timer?
    var soundID: SystemSoundID = 0
    
    var alarmWindow: UIWindow?
    var alarmsViewModel: AlarmsViewModel?
    var userViewModel: UserViewModel?
    var friendViewModel: FriendsViewModel?
    
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
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("APNs Device Token: \(tokenString)")
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
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        if let userId = Auth.auth().currentUser?.uid {
            updateUserToken(userId, fcmToken ?? "")
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
            // self.startLongVibration()
        } else {
//            if let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") {
//                triggerFirebaseAlarmFunction(fcmToken: fcmToken)
//            }
        }
        completionHandler([.banner, .sound])
    }

    // Handle notification when app is in the background or closed
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("UNNotificationResponse did Receive")
        let userInfo = response.notification.request.content.userInfo
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        if response.notification.request.content.categoryIdentifier == "alarm" {
            switch response.actionIdentifier {
            case "ACCEPT_ACTION":
                handleNotification(userInfo: userInfo)
                
            case "DECLINE_ACTION":
                print("User declined")
                
            case UNNotificationDefaultActionIdentifier:
                presentAlarmRequestView(userInfo: userInfo)  // Ensure this gets triggered for the default action
                
            case UNNotificationDismissActionIdentifier:
                print("User dismissed")
                
            default:
                break
            }
            completionHandler()
        } else {
//            if let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") {
//                triggerFirebaseAlarmFunction(fcmToken: fcmToken)
//            }
        }
    }
    
    @MainActor
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

    func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
    }
    
    private func handleNotification(userInfo: [AnyHashable: Any]) {
        print("Received data message: \(userInfo)")
        if let id = userInfo["id"] as? String,
           let title = userInfo["title"] as? String,
           let body = userInfo["alarmBody"] as? String,
           let alarmTimeString = userInfo["alarmTime"] as? String,
           let sound = userInfo["sound"] as? String,
           let ringtoneURL = userInfo["ringtoneURL"] as? String?,
           let _ = userInfo["repeat"] as? String,
           let _ = userInfo["groupId"] as? String,
           let _ = userInfo["groupName"] as? String {
           
            print("alarmTimeString: \(alarmTimeString)")

            // Date formatter configuration
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let alarmTime = dateFormatter.date(from: alarmTimeString) {
                // Debug information for parsed date
                scheduleLocalNotification(id: id, title: title, body: body, alarmTime: alarmTime, sound: sound, ringtoneURL: ringtoneURL)
            } else {
                // Debug information for date parsing failure
                print("Failed to parse alarmTimeString: \(alarmTimeString)")
            }
        } else {
            print("This might be an Alarm")
        }
    }
    
//    func presentAlarmView() {
//        // Create a window and set the root view controller to your custom SwiftUI view
//        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let rootViewController = scene.windows.first?.rootViewController {
//            let rootView = AlarmView(alarmViewModel: AlarmsViewModel())
//            let sheetController = SheetHostingController(rootView: rootView)
//
//            rootViewController.present(sheetController, animated: true, completion: nil)
//        } else {
//            print("No suitable window scene found.")
//        }
//    }
    
    func presentAlarmRequestView(userInfo: [AnyHashable : Any]) {
        print("Present request View \(userInfo)")
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            print("Unable to find root view controller.")
            return
        }

        // Check if there's already a presented view controller
        if let presentedVC = rootViewController.presentedViewController {
            // Dismiss the currently presented view controller
            presentedVC.dismiss(animated: true) {
                // Call the function again after dismissing to present the AlarmRequestView
                self.presentAlarmRequestView(userInfo: userInfo)
            }
            return
        }
        
        if let id = userInfo["id"] as? String,
           let _ = userInfo["title"] as? String,
           let alarmBody = userInfo["body"] as? String,
           let alarmTimeString = userInfo["alarmTime"] as? String,
           let sound = userInfo["sound"] as? String,
           let repeatInterval = userInfo["repeat"] as? String,
           let groupId = userInfo["groupId"] as? String,
           let groupName = userInfo["groupName"] as? String {
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let alarmTime = dateFormatter.date(from: alarmTimeString), let userViewModel = userViewModel, let alarmsViewModel = alarmsViewModel {
                let rootView = AlarmRequestView(userViewModel: userViewModel, alarmViewModel: alarmsViewModel, alarm: Alarm(id: id, time: alarmTime, sound: sound, alarmBody: alarmBody, repeatInterval: repeatInterval, groupId: groupId, groupName: groupName))
                let hostingController = UIHostingController(rootView: rootView)
                hostingController.modalPresentationStyle = .pageSheet
                
                // Present the hosting controller
                rootViewController.present(hostingController, animated: true, completion: nil)
            } else {
                print("Failed to parse alarmTimeString: \(alarmTimeString)")
            }
        }
    }

    public func scheduleLocalNotification(id: String, title: String, body: String, alarmTime: Date, sound: String, ringtoneURL: String?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let ringtoneURL = ringtoneURL {
            cacheSoundFromURL(ringtoneURL) { cachedURL in
                guard let cachedURL = cachedURL else { return }
                do {
                    let filename = "downloadedRecording.caf"
                    let targetURL = try FileManager.default.soundsLibraryURL(for: filename)
                    
                    // Remove existing file if present
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    
                    // Copy the file to /Library/Sounds
                    try FileManager.default.copyItem(at: cachedURL, to: targetURL)
                    
                    // Set file protection and permissions to be readable by the system
                    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: targetURL.path)
                    try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: targetURL.path) // rw-r--r--
                } catch {
                    print("Error copying sound file: \(error)")
                }
            }
            content.sound = UNNotificationSound(named: UNNotificationSoundName("downloadedRecording.caf"))
        } else {
            if sound == "YourRecording.caf" {
                do {
                    print("Using recording locally")
                    let docsurl = try FileManager.default.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let myurl = docsurl.appendingPathComponent("Recording.caf")
                    let filename = myurl.lastPathComponent
                    let targetURL = try FileManager.default.soundsLibraryURL(for: filename)
                    
                    // copy audio file to /Library/Sounds
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    try FileManager.default.copyItem(at: myurl, to: targetURL)
                    content.sound = UNNotificationSound(named: UNNotificationSoundName(filename))
                } catch {
                    print("Error copying sound file: \(error)")
                }
            } else {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
                print("Using sound \(sound)")
            }
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: alarmTime), repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error)")
            } else {
                print("Local notification scheduled.")
            }
        }
    }
    
    func extractFilename(from urlString: String) -> String {
            // Decode the URL string to handle the encoded characters
            guard let decodedUrl = urlString.removingPercentEncoding else { return "" }
            
            // Find the range of the token after the "token=" part
            if let range = decodedUrl.range(of: "token=") {
                // Extract the substring starting from the token
                let token = decodedUrl[range.upperBound...]
                return String(token)
            }
            
            return "Token not found"
        }
    
    public func cancelScheduledLocalNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cacheSoundFromURL(_ urlString: String, completion: @escaping (URL?) -> Void) {
        print("caching sound from \(urlString)")
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                completion(nil)
                return
            }
            completion(localURL)
        }
        task.resume()
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
}

extension AppDelegate {
    func triggerFirebaseAlarmFunction(fcmToken: String) {
        print("Triggering Firebase Alarm Function")
        let urlString = "https://us-central1-sharingalarm.cloudfunctions.net/sendAlarmSound"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "fcmToken": fcmToken
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
        } catch let error {
            print("Failed to serialize request body: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error triggering function: \(error)")
                return
            }
            guard let data = data else { return }
            let responseString = String(data: data, encoding: .utf8)
            print("Response from Firebase Function: \(responseString ?? "No response")")
        }

        task.resume()
    }
}

// ActivityKit
extension AppDelegate {
    func startAlarmLiveActivity(remainingTime: TimeInterval, alarmBody: String) {
        let initialContentState = AlarmAttributes.ContentState(remainingTime: remainingTime, alarmBody: alarmBody)
        let attributes = AlarmAttributes(alarmBody: alarmBody)

        do {
            let activity = try Activity<AlarmAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: nil)
            updateAlarmLiveActivity(alarm: activity, remainingTime: remainingTime)
            print("Started Live Activity")
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    func updateAlarmLiveActivity(alarm: Activity<AlarmAttributes>, remainingTime: TimeInterval) {
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            let remainingTime = remainingTime - 1
            let contentState = AlarmAttributes.ContentState(remainingTime: remainingTime, alarmBody: alarm.attributes.alarmBody)

            Task {
                await alarm.update(using: contentState)
            }

            if remainingTime == 0 {
                timer.invalidate()
                self.endAlarmLiveActivity(activity: alarm)
            }
        }
    }

    func endAlarmLiveActivity(activity: Activity<AlarmAttributes>) {
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
    }
}
