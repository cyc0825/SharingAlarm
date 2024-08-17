//
//  AlarmRequestView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/8/16.
//

import Foundation
import SwiftUI

struct AlarmRequestView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var alarmViewModel: AlarmsViewModel
    var alarm: Alarm
    
    var body: some View {
        ZStack {
            Color.thirdAccent.ignoresSafeArea(edges: .all)
            HStack {
                Button {
                    print("Add Alarm \(alarm.id ?? "")")
                    alarmViewModel.alarms.append(alarm)
                    dismiss()
                } label: {
                    Text("Accept")
                }
                Button {
                    dismiss()
                } label: {
                    Text("Reject")
                }
            }
            .padding()
        }
    }
}

#Preview {
    AlarmRequestView(alarmViewModel: AlarmsViewModel(), alarm: Alarm(time: Date(), sound: "", repeatInterval: ""))
}
