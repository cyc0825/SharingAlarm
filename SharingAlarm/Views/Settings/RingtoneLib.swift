//
//  FreeRingtone.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/8.
//

import SwiftUI
import AVFoundation

struct RingtoneLib: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject var viewModel: AlarmsViewModel
    @State var showConfirmView = false
    @State var selectedRingtone: Ringtone? = nil
    @State private var showPartyPopper = false
    @State private var audioPlayer: AVAudioPlayer?
    var userID = UserDefaults.standard.string(forKey: "userID") ?? ""
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.premiumRingtones, id: \.self) { ringtone in
                    HStack {
                        Button(action: {
                            playSound(named: ringtone.name)
                        }) {
                            Text(ringtone.name)
                        }
                        Spacer()
                        Button(action: {
                            selectedRingtone = ringtone
                            showConfirmView = true
                        }) {
                            HStack {
                                Image(systemName: "seal.fill")
                                Text("\(ringtone.price)")
                            }
                            .frame(width: 60)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                HStack {
                    Image(systemName: "seal.fill")
                        .foregroundStyle(.accent)
                    Text("\(userViewModel.appUser.money)")
                        .foregroundStyle(.accent)
                }
            }
        }
        .navigationTitle("Ringtone Shop")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConfirmView) {
            ZStack {
                VStack {
                    Text("Are you sure you want to unlock this ringtone?")
                        .font(.headline)
                        .padding(.top)
                    Spacer()
                    HStack(spacing: 20) {
                        Button(action: {
                            showConfirmView = false
                        }) {
                            Text("Cancel")
                        }
                        .tint(.gray)
                        .buttonStyle(.borderedProminent)
                        Button(action: {
                            Task {
                                if let ringtone = selectedRingtone, let ringtoneID = ringtone.id {
                                    let success = try await EconomyViewModel.shared.unlockRingtone(userID: userID, ringtoneID: ringtoneID, cost: ringtone.price)
                                    if success {
                                        if let index = viewModel.premiumRingtones.firstIndex(where: { $0.id == ringtoneID }) {
                                            let ringtone = viewModel.premiumRingtones.remove(at: index)
                                            viewModel.ringtones.append(ringtone)
                                            userViewModel.appUser.money -= ringtone.price
                                            showPartyPopper = true // Show the party popper animation
                                            
                                            // Automatically hide the popper after 1 second
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                showPartyPopper = false
                                                showConfirmView = false
                                            }
                                        }
                                    } else {
                                        viewModel.errorMessage = "Insufficient coins"
                                    }
                                }
                            }
                        }) {
                            Text("Unlock")
                        }
                        
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
                    Alert(title: Text("Cannot Unlock"),
                          message: Text(viewModel.errorMessage ?? "Unknown Error"),
                          dismissButton:.default(Text("Confirm"), action: {
                        viewModel.errorMessage = nil
                    })
                    )
                }
                .padding()
                .presentationDetents([.height(200)])
                if showPartyPopper {
                    PartyPopperView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }
    
    private func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "caf") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}
