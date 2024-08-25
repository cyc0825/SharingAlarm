//
//  VoiceViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/19.
//

import SwiftUI
import AVFoundation
import FirebaseStorage

class AudioRecorderViewModel: ObservableObject {
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var player: AVPlayer?
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordedAudioURL: URL?

    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("Recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordedAudioURL = audioRecorder?.url
    }

    func playRecording() {
        guard let url = recordedAudioURL, FileManager.default.fileExists(atPath: url.path) else {
            print("Recording file does not exist at URL: \(recordedAudioURL?.path ?? "nil")")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }

    func uploadRecordingToFirebase() {
        guard let recordedAudioURL = recordedAudioURL else { return }
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        
        let storageRef = Storage.storage().reference()
        let audioRef = storageRef.child("recordings/\(userID)/Recording.m4a")

        audioRef.putFile(from: recordedAudioURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload recording: \(error.localizedDescription)")
            } else {
                audioRef.downloadURL { url, error in
                    if let error = error {
                        print("Failed to get download URL: \(error.localizedDescription)")
                    } else if let downloadURL = url {
                        print("Download URL: \(downloadURL)")
                        // Save this URL for later use
                        UserDefaults.standard.set(downloadURL.absoluteString, forKey: "alarmSoundURL")
                    }
                }
            }
        }
    }
    
    func loadLocalRecording(completion: @escaping (Bool) -> Void) {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("Recording.m4a")
        if FileManager.default.fileExists(atPath: audioFilename.path) {
            recordedAudioURL = audioFilename
            completion(true)
        }
        completion(false)
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func deleteRecording() {
        guard let downloadURLString = UserDefaults.standard.string(forKey: "alarmSoundURL"),
              let audioRef = getFirebaseStorageReference(for: downloadURLString) else {
            print("Failed to get the Firebase reference for the stored alarm.")
            return
        }
        audioRef.delete { error in
            if let error = error {
                print("Failed to delete alarm: \(error.localizedDescription)")
            } else {
                print("Alarm successfully deleted.")
                let audioFilename = self.getDocumentsDirectory().appendingPathComponent("YourRecording.m4a")
                self.recordedAudioURL = nil
                try? FileManager.default.removeItem(at: audioFilename)
                UserDefaults.standard.removeObject(forKey: "alarmSoundURL")
            }
        }
    }
    
    private func getFirebaseStorageReference(for urlString: String) -> StorageReference? {
        let storageRef = Storage.storage().reference()
        
        // Extract the path from the full URL
        if let url = URL(string: urlString), let path = url.pathComponents.dropFirst(5).joined(separator: "/") as String? {
            return storageRef.child(path)
        }
        
        return nil
    }
}

// For player sound in notificication
extension AudioRecorderViewModel {
    func playSound(soundName: String) {
        let storageRef = Storage.storage().reference()
        let path = "recordings\(soundName)"
        let soundRef = storageRef.child(path)
        print("Playing from \(path)")
        soundRef.downloadURL { url, error in
            guard let url else { print("Error: \(error?.localizedDescription ?? "")"); return }
            print("Play recording: \(url.absoluteString)")
            let playerItem = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem: playerItem)
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .duckOthers])
            } catch { print("Error: \(error.localizedDescription)") }
            self.player?.play()
            self.isPlaying = true
            NotificationCenter.default.addObserver(self, selector: #selector(self.audioDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
    }

    @objc private func audioDidFinishPlaying() {
        isPlaying = false
        player = nil
    }
    
    func stopPlaying() {
        player?.pause()
        isPlaying = false
    }
}
