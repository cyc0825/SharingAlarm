//
//  VoiceViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/19.
//

import SwiftUI
import AVFoundation
import FirebaseStorage

class AudioRecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var player: AVPlayer?
    var timer: Timer?
    var playbackTimer: Timer?
    var recordingTimer: Timer?
    var timeRemaining = 10 // Maximum recording duration in seconds
    var soundData: [Float] = [] // Store recorded audiogram data here
    var currentAudiogramIndex = 0 // Track the current position of audiogram playback
    var previousSoundData: [Float] = [] // Store the previous recording's audiogram data for reverting
    var previousRecordingURL: URL? // Store the previous recording URL
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordedAudioURL: URL?
    @Published var audiogramData: [Float] = []
    @Published var displayAudiogramData: [Float] = [] // Data used for displaying during playback

    func startRecording() {
        guard !isPlaying else { return } // Prevent starting a recording while playing

        // Setup AVAudioSession before starting recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up AVAudioSession: \(error.localizedDescription)")
            return
        }

        let audioFilename = getDocumentsDirectory().appendingPathComponent("Recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord() // Prepare the recorder before starting
            audioRecorder?.record()
            isRecording = true
            audiogramData = Array(repeating: 0.0, count: 50)
            // Save the current recording as the previous one before uploading
            previousRecordingURL = recordedAudioURL
            previousSoundData = soundData
            soundData = []
            
            // Start the recording duration timer
            startRecordingTimer()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                self.updateAudiogram()
            }
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
            // Handle the error gracefully, reset states if needed
            isRecording = false
            audioRecorder = nil
        }
    }
    
    private func startRecordingTimer() {
        timeRemaining = 10 // Reset to the maximum recording duration
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.timeRemaining -= 1
            print("Time remaining: \(self.timeRemaining) seconds")
            
            if self.timeRemaining <= 0 {
                // Time's up, stop the recording automatically
                self.stopRecording()
            }
        }
    }


    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordedAudioURL = audioRecorder?.url
        
        // Save the current audiogram data for future playback
        saveAudiogramData()
        let halfEmptyValues: [Float] = Array(repeating: 0.0, count: 25)
        audiogramData = halfEmptyValues + Array(soundData.prefix(25))
        timer?.invalidate()
        recordingTimer?.invalidate()
    }
    
    func saveAudiogramData() {
        let audiogramDataURL = getDocumentsDirectory().appendingPathComponent("audiogramData.json")

        do {
            // Convert audiogramData to JSON data
            let data = try JSONEncoder().encode(soundData)
            try data.write(to: audiogramDataURL)
            print("Audiogram data saved successfully at: \(audiogramDataURL.path)")
        } catch {
            print("Failed to save audiogram data: \(error.localizedDescription)")
        }
    }

    func updateAudiogram() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        let normalizedLevel = max(0.0, min(1.0, (level + 50) / 50)) // Normalize level to 0...1 range
        soundData.append(normalizedLevel)
        audiogramData.append(normalizedLevel)
        
        if audiogramData.count > 50 { // Keep the display limited to a fixed number of capsules
            audiogramData.removeFirst()
        }
    }

    func playRecording() {
        guard let url = recordedAudioURL, FileManager.default.fileExists(atPath: url.path), !isRecording else {
            print("Cannot play while recording or file does not exist.")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            
            // Load the saved audiogram data for playback visualization
            displayAudiogramData = soundData
            displayAudiogramData = displayAudiogramData + Array(repeating: 0.0, count: 25)
            currentAudiogramIndex = 25
            let halfEmptyValues: [Float] = Array(repeating: 0.0, count: 25)
            audiogramData = halfEmptyValues + Array(displayAudiogramData.prefix(25))
            startAudiogramPlayback()
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }

    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
        stopAudiogramPlayback()
    }

    // Automatically set isPlaying to false when audio finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopAudiogramPlayback() // Stop the audiogram playback when the audio ends
    }

    private func startAudiogramPlayback() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard self.isPlaying, self.currentAudiogramIndex < self.displayAudiogramData.count else {
                self.stopAudiogramPlayback()
                return
            }

            // Update the audiogram to display only up to the current index
            self.audiogramData.append(self.displayAudiogramData[self.currentAudiogramIndex])
            if self.audiogramData.count > 50 {
                self.audiogramData.removeFirst() // Remove the oldest capsule to keep it moving
            }
            self.currentAudiogramIndex += 1 // Move to the next part of the audiogram data
        }
    }

    private func stopAudiogramPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func loadLocalRecording(completion: @escaping (Bool) -> Void) {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("Recording.m4a")
        if FileManager.default.fileExists(atPath: audioFilename.path) {
            recordedAudioURL = audioFilename
            // Load any saved audiogram data if needed
            loadAudiogramData()
            audiogramData = soundData // Load previously saved data if available
            completion(true)
        } else {
            completion(false)
        }
    }

    func loadAudiogramData() {
        let audiogramDataURL = getDocumentsDirectory().appendingPathComponent("audiogramData.json")

        do {
            let data = try Data(contentsOf: audiogramDataURL)
            soundData = try JSONDecoder().decode([Float].self, from: data)
            print("Audiogram data loaded successfully.")
        } catch {
            print("Failed to load audiogram data: \(error.localizedDescription)")
            soundData = [] // Default to an empty array if loading fails
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

extension AudioRecorderViewModel {
    func uploadRecording() {
        guard let recordedAudioURL = recordedAudioURL else { return }
        guard let userID = UserDefaults.standard.value(forKey: "userID") as? String else { return }
        
        // Upload to Firebase Storage
        let storageRef = Storage.storage().reference()
        let audioRef = storageRef.child("recordings/\(userID)/Recording.m4a")
        audioRef.putFile(from: recordedAudioURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload recording: \(error.localizedDescription)")
                return
            }
            audioRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    return
                }
                print("Upload successful, download URL: \(url?.absoluteString ?? "No URL")")
                // Update any stored URLs as needed here
            }
        }
    }
    
    func discardNewRecording() {
        if let previousURL = previousRecordingURL {
            recordedAudioURL = previousURL
            soundData = previousSoundData
            audiogramData = Array(repeating: 0.0, count: 25) + Array(previousSoundData.prefix(25))
            print("Reverted to previous recording.")
        } else {
            // If no previous recording exists, clear the data
            recordedAudioURL = nil
            soundData = []
            audiogramData = Array(repeating: 0.0, count: 50)
            print("No previous recording found. Cleared current recording.")
        }
    }
}
