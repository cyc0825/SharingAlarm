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
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        startAudioWork()
        sendLocalNotification(identifier: request.identifier, body: bestAttemptContent?.body)
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
            
            contentHandler(bestAttemptContent)
        }
    }
    
    private func sendLocalNotification(identifier: String, body: String?) {
        let content = UNMutableNotificationContent()
        content.body = body ?? ""
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        stopAudioWork()
            
        if let handler = self.contentHandler, let content = self.bestAttemptContent {
            content.body = "[You miss the alarm]"
            handler(content)
        }
    }

    private func startAudioWork() {
        let audioPath = Bundle.main.path(forResource: "beep-04", ofType: "mp3")
        let fileUrl = URL(string: audioPath ?? "")
        AudioServicesCreateSystemSoundID(fileUrl! as CFURL, &soundID)
        AudioServicesPlayAlertSound(soundID)
        AudioServicesAddSystemSoundCompletion(soundID, nil, nil, {sound, clientData in
            AudioServicesPlayAlertSound(sound)
        }, nil)
    }

    private func stopAudioWork() {
        AudioServicesRemoveSystemSoundCompletion(soundID)
        AudioServicesDisposeSystemSoundID(soundID)
    }
}
