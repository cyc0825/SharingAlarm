//
//  FreeRingtone.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/8.
//

import SwiftUI

struct RingtoneLib: View {
    @ObservedObject var viewModel = AlarmsViewModel()
    var ringToneType: String = "Free"
    var body: some View {
        List {
            if ringToneType == "Free" {
                ForEach(viewModel.sounds, id: \.self) { sounds in
                    Text(sounds)
                }
            } else if ringToneType == "Premium" {
                ForEach(viewModel.paidSounds, id: \.self) { sounds in
                    Text(sounds)
                }
            }
        }
    }
}
