//
//  Untitled.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/26.
//

import SwiftUI
import UIKit

struct IconSelectionView: View {
    @ObservedObject var iconManager = AppIconManager.shared
    
    // Define grid layout
    let columns = [
        GridItem(.adaptive(minimum: 70))
    ]
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(iconManager.availableIcons) { icon in
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
                VStack(alignment: .leading) {
                    Text("Responde to Alarms at night")
                    HStack {
                        Text("34/100")
                        ProgressView(value: 0.34)
                            .progressViewStyle(.linear)
                        Image(uiImage: UIImage(named: "icon3") ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(12)
                    }
                }
                VStack(alignment: .leading)  {
                    Text("Responde to Alarms at day")
                    HStack {
                        Text("0/100")
                        ProgressView(value: 0)
                            .progressViewStyle(.linear)
                        Image(uiImage: UIImage(named: "icon4") ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(12)
                    }
                }
                VStack(alignment: .leading)  {
                    Text("Schedule your first alarm")
                    HStack {
                        Text("0/1")
                        ProgressView(value: 0)
                            .progressViewStyle(.linear)
                        Image(uiImage: UIImage(named: "icon5") ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(12)
                    }
                }
            } header: {
                Text("Tasks")
                    .font(.title.bold())
            }
            .headerProminence(.increased)
        }
        .navigationTitle("App Icons")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct IconItemView: View {
    let icon: AppIconManager.AppIcon
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
    
    // Define available icons with display names and asset names
    struct AppIcon: Identifiable {
        let id = UUID()
        let displayName: String
        let iconName: String? // nil for default icon
        let imageName: String
    }
    
    let availableIcons: [AppIcon] = [
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

struct IconSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        IconSelectionView()
    }
}
