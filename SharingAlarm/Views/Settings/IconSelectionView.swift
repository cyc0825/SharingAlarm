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
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
//                Text("Select App Icon")
//                    .font(.headline)
//                    .padding([.leading, .top], 20)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(iconManager.availableIcons) { icon in
                        IconItemView(icon: icon, isSelected: iconManager.currentIconName == icon.iconName)
                            .onTapGesture {
                                iconManager.changeAppIcon(to: icon)
                            }
                    }
                }
                .padding()
                
                Spacer()
            }
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
        AppIcon(displayName: "Classic", iconName: nil, imageName: "AppIcon"),
        AppIcon(displayName: "CalenderAlarm", iconName: "icon1", imageName: "icon1"),
        AppIcon(displayName: "PunkAlarm", iconName: "icon2", imageName: "icon2"),
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
