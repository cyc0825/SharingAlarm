//
//  NotificationService.swift
//  Notification
//
//  Created by 曹越程 on 2024/8/23.
//

import UserNotifications
import AVFoundation

class NotificationService: UNNotificationServiceExtension {
    var soundID: SystemSoundID = 0
    var audioPlayer: AVAudioPlayer?
    var ringToneName: String?
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    private var vibrationTimer: DispatchSourceTimer?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        ringToneName = request.content.userInfo["ringTone"] as? String
        // Check the category identifier to decide whether to modify the notification
        if request.content.categoryIdentifier == "alarmVibrate" {
            startAudioWork()
            // startRingtone()
            if let bestAttemptContent = bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
        } else {
            if let bestAttemptContent = bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    private func sendLocalNotification(identifier: String, body: String?) {
        let content = UNMutableNotificationContent()
        content.body = body ?? ""
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    override func serviceExtensionTimeWillExpire() {
        print("extensionTimeWillExpire")
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        stopAudioWork()
            
        if let handler = self.contentHandler, let content = self.bestAttemptContent {
            content.body = "[You miss the alarm]"
            handler(content)
        }
    }

    private func startAudioWork() {
        print("startAudioWork")
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, nil, nil, { sound, clientData in
            print("start Vibrate")
            sleep(1)
            AudioServicesPlaySystemSound(sound)  // Replay the vibration
        }, nil)
    }
    
    
    private func startRingtone() {
        // Safely unwrap the path and create the sound ID
        guard let audioPath = Bundle.main.path(forResource: "Classic", ofType: "caf"),
              let fileUrl = URL(string: audioPath) else {
            print("Failed to find the ringtone file.")
            return
        }

        // Create and play the ringtone sound
        AudioServicesCreateSystemSoundID(fileUrl as CFURL, &soundID)
        AudioServicesPlayAlertSound(soundID)
        AudioServicesAddSystemSoundCompletion(soundID, nil, nil, { sound, clientData in
            AudioServicesPlayAlertSound(sound) // Replay the ringtone
        }, nil)
    }

    private func stopAudioWork() {
        print("Stop Audio Work")
        vibrationTimer?.cancel()
        vibrationTimer = nil
        AudioServicesRemoveSystemSoundCompletion(soundID)
        AudioServicesDisposeSystemSoundID(soundID)
    }
}
