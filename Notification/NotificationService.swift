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
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        // Check the category identifier to decide whether to modify the notification
        if request.content.categoryIdentifier == "alarmVibrate" {
            startAudioWork()
            startRingtone()
            if let bestAttemptContent = bestAttemptContent {
                // Modify the notification content here...
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
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        stopAudioWork()
            
        if let handler = self.contentHandler, let content = self.bestAttemptContent {
            content.body = "[You miss the alarm]"
            handler(content)
        }
    }

    private func startAudioWork() {
//        let audioPath = Bundle.main.path(forResource: "Classic", ofType: "m4a")
//        let fileUrl = URL(string: audioPath ?? "")
//        AudioServicesCreateSystemSoundID(fileUrl! as CFURL, &soundID)
//        AudioServicesPlayAlertSound(soundID)
//        AudioServicesAddSystemSoundCompletion(soundID, nil, nil, {sound, clientData in
//            AudioServicesPlayAlertSound(sound)
//        }, nil)
//        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, nil, nil, { sound, clientData in
            sleep(1)
            AudioServicesPlaySystemSound(sound)  // Replay the vibration
        }, nil)
    }
    
    private func startRingtone() {
        guard let audioPath = Bundle.main.path(forResource: "beep-04", ofType: "mp3"),
              let audioURL = URL(string: audioPath) else {
            print("Audio file not found.")
            return
        }
        
        do {
            // Initialize AVAudioPlayer with the audio file URL
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }

    private func stopAudioWork() {
        AudioServicesRemoveSystemSoundCompletion(soundID)
        AudioServicesDisposeSystemSoundID(soundID)
    }
}
