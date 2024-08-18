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
            Color.accentColor.ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
                Text(alarm.time.formatted(date: .long, time: .omitted))
                    .font(.title)
                    .fontDesign(.serif)
                Text(alarm.time.formatted(date: .omitted, time: .shortened))
                    .font(.largeTitle)
                    .fontDesign(.serif)
                Spacer()
                Button {
                    print("Add Alarm \(alarm.id ?? "")")
                    if let id = alarm.id {
                        alarmViewModel.addAlarmToParticipant(alarmId: id, activityId: alarm.activityID ?? "", isOn: true) { result in
                            switch result {
                            case .success(_):
                                print("Success")
                            case .failure(_):
                                print("fail")
                            }
                        }
                    }
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(.systemText)
                }
                .background(Color.green)
                .cornerRadius(25)
                .padding(.horizontal)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(.systemText)
                }
                .background(Color.red)
                .cornerRadius(25)
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .padding()
        }
    }
}

#Preview {
    AlarmRequestView(alarmViewModel: AlarmsViewModel(), alarm: Alarm(time: Date(), sound: "", repeatInterval: ""))
}
