//
//  Untitled.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/26.
//

import SwiftUI
import UIKit

// Define available icons with display names and asset names
struct AppIcon: Identifiable {
    let id = UUID()
    let displayName: String
    let iconName: String? // nil for default icon
    let imageName: String
}

struct IconSelectionView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject var iconManager = AppIconManager.shared
    @State var showPartyPopper: Bool = false
    
    var iconTasks: [IconTask] {
        return [
            IconTask(
                task: "Schedule your first alarm",
                iconReward: "icon5",
                progress: userViewModel.appUser.alarmScheduled,
                goal: 1
            ),
            IconTask(
                task: "Schedule alarms",
                iconReward: "icon6",
                progress: userViewModel.appUser.alarmScheduled,
                goal: 20
            ),
            IconTask(
                task: "Responde to Alarms at nighttime",
                iconReward: "icon3",
                progress: userViewModel.appUser.alarmResponsedNight,
                goal: 20
            ),
            IconTask(
                task: "Responde to Alarms at nighttime",
                iconReward: "icon9",
                progress: userViewModel.appUser.alarmResponsedNight,
                goal: 100
            ),
            IconTask(
                task: "Responde to Alarms at daytime",
                iconReward: "icon4",
                progress: userViewModel.appUser.alarmResponsedDay,
                goal: 20
            ),
            IconTask(
                task: "Responde to Alarms at daytime",
                iconReward: "icon8",
                progress: userViewModel.appUser.alarmResponsedDay,
                goal: 100
            ),
            IconTask(
                task: "Responde to Alarms",
                iconReward: "icon7",
                progress: userViewModel.appUser.alarmResponsed,
                goal: 50
            )
        ]
    }
    
    var imcompleteIconTask: [IconTask] {
        iconTasks.filter { task in
            return !userViewModel.appUser.unlockedIcons.contains(task.iconReward)
        }
    }
    // Define grid layout
    let columns = [
        GridItem(.adaptive(minimum: 70))
    ]
    
    var availableIcons: [AppIcon] {
        AppIconManager.shared.allIcons.filter { icon in
            if icon.iconName == nil {
                // this is default icon
                return true
            } else if (icon.iconName == "icon10" ||
                       icon.iconName == "icon11" ||
                       icon.iconName == "icon12" ||
                       icon.iconName == "icon13") &&
                        UserDefaults.standard.bool(forKey: "isPremium")  {
                // this is premium icon
                return true
            }
            
            return userViewModel.appUser.unlockedIcons.contains(icon.iconName!)
        }
    }
    
    var body: some View {
        ZStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(availableIcons) { icon in
                                IconItemView(icon: icon, isSelected: iconManager.currentIconName == icon.iconName)
                                    .onTapGesture {
                                        iconManager.changeAppIcon(to: icon)
                                    }
                            }
                        }
                        
                    }
                } header: {
                    Text("App Icons")
                        .font(.title.bold())
                }
                .headerProminence(.increased)
                Section {
                    List(imcompleteIconTask, id: \.self) { task in
                        if task.progress < task.goal {
                            VStack(alignment: .leading)  {
                                HStack {
                                    Text("\(task.task)")
                                    Spacer()
                                    Text("\(task.progress * 100 / task.goal)%")
                                }
                                HStack {
                                    ProgressView(value: Double(task.progress) / Double(task.goal))
                                        .progressViewStyle(.linear)
                                    Image(uiImage: UIImage(named: task.iconReward) ?? UIImage())
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(12)
                                }
                            }
                        } else {
                            Button {
                                Task {
                                    let success = try await EconomyViewModel.shared.unlockIcon(iconID: task.iconReward)
                                    if success {
                                        userViewModel.appUser.unlockedIcons.append(task.iconReward)
                                    } else {
                                        print("Internet Error for unlocking \(task.iconReward)")
                                    }
                                    showPartyPopper = true
                                }
                            } label : {
                                VStack(alignment: .center) {
                                    Image(uiImage: UIImage(named: task.iconReward) ?? UIImage())
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(12)
                                    Text("Claim Your Reward")
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                } header: {
                    Text("Tasks")
                        .font(.title.bold())
                } footer: {
                    Text("Only alarms that are scheduled for 2 hours will be counted as alarm responded, if the data is not updating correctly, please refresh the app.")
                }
                .headerProminence(.increased)
            }
            .navigationTitle("App Icons")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            if showPartyPopper {
                PartyPopperView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .onAppear {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
            }
        }
    }
}

struct IconItemView: View {
    let icon: AppIcon
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(uiImage: UIImage(named: icon.imageName) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 4)
                )
                .shadow(color: isSelected ? Color.accentColor.opacity(0.4) : Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            Text(icon.displayName)
                .font(.footnote)
                .foregroundColor(.primary)
        }
        .opacity(isSelected ? 1.0 : 0.8)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}


class AppIconManager: ObservableObject {
    static let shared = AppIconManager()
    
    @Published var currentIconName: String?
    
    public var allIcons: [AppIcon] = [
        AppIcon(displayName: "Classic", iconName: nil, imageName: "AppIconDefault"),
        AppIcon(displayName: "Calender", iconName: "icon1", imageName: "icon1"),
        AppIcon(displayName: "Punk", iconName: "icon2", imageName: "icon2"),
        AppIcon(displayName: "Night", iconName: "icon3", imageName: "icon3"),
        AppIcon(displayName: "Day", iconName: "icon4", imageName: "icon4"),
        AppIcon(displayName: "Stick", iconName: "icon5", imageName: "icon5"),
        AppIcon(displayName: "SKetch", iconName: "icon6", imageName: "icon6"),
        AppIcon(displayName: "Sky", iconName: "icon7", imageName: "icon7"),
        AppIcon(displayName: "Flower", iconName: "icon8", imageName: "icon8"),
        AppIcon(displayName: "Forest", iconName: "icon9", imageName: "icon9"),
        AppIcon(displayName: "Premium", iconName: "icon10", imageName: "icon10"),
        AppIcon(displayName: "Infinite", iconName: "icon11", imageName: "icon11"),
        AppIcon(displayName: "Audiogram", iconName: "icon12", imageName: "icon12"),
        AppIcon(displayName: "Badge", iconName: "icon13", imageName: "icon13"),
        // Add more icons as needed
    ]
    
    private init() {
        fetchCurrentIconName()
    }
    
    func fetchCurrentIconName() {
        currentIconName = UIApplication.shared.alternateIconName
    }
    
    func changeAppIcon(to icon: AppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons are not supported on this device.")
            return
        }
        
        // Prevent changing to the same icon
        if currentIconName == icon.iconName {
            print("Icon already set to \(icon.displayName).")
            return
        }
        
        UIApplication.shared.setAlternateIconName(icon.iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            } else {
                print("App icon changed to: \(icon.displayName)")
                DispatchQueue.main.async {
                    self.currentIconName = icon.iconName
                }
            }
        }
    }
}

//struct IconSelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        IconSelectionView()
//    }
//}
