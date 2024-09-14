//
//  SharingAlarmApp.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import CloudKit

import Firebase
import FirebaseCore
import FirebaseMessaging

import UIKit
import TipKit
import AVFoundation
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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var showLaunchScreen = true
    
    init() {
        try? Tips.configure()
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
                    }
            } else if authViewModel.authenticationState == .authenticated {
                NavigationView {
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
                }
            } else {
                NavigationView {
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
                        Spacer()
                    }
                    .onAppear {
                        appDelegate.alarmsViewModel = alarmsViewModel
                    }
                    .preferredColorScheme(selectedAppearance.colorScheme)
                }
            }
        }
    }
}

func scheduleNotification(for alarm: Alarm, viewModel: AlarmsViewModel) {
    let content = UNMutableNotificationContent()
    content.title = "Alarm"
    content.body = "Your alarm is going off!"
    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "Classic.m4a"))
    
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
    var soundID: SystemSoundID = 0
    
    var alarmWindow: UIWindow?
    var alarmsViewModel: AlarmsViewModel?
    
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
    
    func presentAlarmView() {
        // Create a window and set the root view controller to your custom SwiftUI view
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = scene.windows.first?.rootViewController {
            let rootView = AlarmView(alarmViewModel: AlarmsViewModel())
            let sheetController = SheetHostingController(rootView: rootView)

            rootViewController.present(sheetController, animated: true, completion: nil)
        } else {
            print("No suitable window scene found.")
        }
    }
    
    func presentAlarmRequestView(userInfo: [AnyHashable : Any]) {
        print("Present request View \(userInfo)")
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController,
              rootViewController.presentedViewController == nil else {
            print("Another view is already presented, cannot present AlarmRequestView.")
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
            
            if let alarmTime = dateFormatter.date(from: alarmTimeString) {
                let rootView = AlarmRequestView(alarmViewModel: AlarmsViewModel(), alarm: Alarm(id: id, time: alarmTime, sound: sound, alarmBody: alarmBody, repeatInterval: repeatInterval, groupID: groupId, groupName: groupName))
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
                    let filename = cachedURL.deletingPathExtension().lastPathComponent + ".m4a"
                    let targetURL = try FileManager.default.soundsLibraryURL(for: filename)
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    try FileManager.default.copyItem(at: cachedURL, to: targetURL)
                    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: targetURL.path)
                    let attributes = try FileManager.default.attributesOfItem(atPath: targetURL.path)
                    print("Copied sound file attributes: \(attributes)")
                    content.sound = UNNotificationSound(named: UNNotificationSoundName(filename))
                    print("Using downloaded recording: \(filename)")
                }
                catch {
                    print("Error copying sound file: \(error)")
                }
            }
        } else {
            if sound == "YourRecording.m4a" {
                do {
                    print("Using recording locally")
                    let docsurl = try FileManager.default.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let myurl = docsurl.appendingPathComponent("Recording.m4a")
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
