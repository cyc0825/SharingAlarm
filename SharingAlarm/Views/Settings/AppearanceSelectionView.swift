//
//  AppearanceSelectionView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/27.
//

import SwiftUI

enum AppearanceOption: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
}

struct AppearanceSelectionView: View {
    @AppStorage("selectedAppearance") private var selectedAppearance: AppearanceOption = .system
    
    var body: some View {
        VStack {
            Circle()
                .fill(.thirdAccent.gradient)
                .frame(width: 150, height: 150)
            Text("Change Color Scheme")
                .font(.title2.bold())
                .padding(.top, 25)
            
            Picker("Appearance", selection: $selectedAppearance) {
                ForEach(AppearanceOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle()) // Use SegmentedPicker for better UX
            Spacer()
        }
        .padding()
    }
}

extension AppearanceOption {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil // System default
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

#Preview {
    AppearanceSelectionView()
}
