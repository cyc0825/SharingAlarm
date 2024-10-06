
import SwiftUI
import AVFoundation

struct UIPlayView: View {
    @Binding var selectedRingtone: Ringtone
    @StateObject var alarmsViewModel: AlarmsViewModel
    @State private var showAddGroupView = false
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        List {
            Section(header: Text("Select a Ringtone")) {
                ForEach(alarmsViewModel.ringtones, id: \.id) { ringtone in
                    Button {
                        if selectedRingtone == ringtone {
                            playSound(named: ringtone.name)
                        } else {
                            audioPlayer?.stop()
                            selectedRingtone = ringtone
                        }
                    } label: {
                        HStack {
                            Text(ringtone.name)
                            Spacer()
                            if selectedRingtone == ringtone {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            if UserDefaults.standard.bool(forKey: "isPremium") {
                Section("User your own voice") {
                    AudioRecorderView(alarmsViewModel: alarmsViewModel)
                    Button {
                        selectedRingtone = Ringtone(name: "YourRecording", filename: "YourRecording.caf", price: 0)
                    } label: {
                        HStack {
                            Text("YourRecording")
                            Spacer()
                            if selectedRingtone.name == "YourRecording" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Section {
                // Option to add a new group
                Button {
                    showAddGroupView = true
                } label: {
                    Text("View Ringtone Library")
                        .foregroundStyle(.systemText)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.accent)
            }
        }
        .sheet(isPresented: $showAddGroupView) {
            RingtoneLib(viewModel: alarmsViewModel)
        }
    }
    
    private func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "caf") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}
