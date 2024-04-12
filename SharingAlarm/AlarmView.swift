//
//  AlarmView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/8.
//

import SwiftUI

struct AlarmView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel = AlarmsViewModel()
    
    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea(edges: .all)
            VStack{
                Spacer()
                Text("Ring Ring Ring")
                
                Spacer()
                
                Button(action: closeAlarm, label: {
                    Text("Close Alarm")
                })
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: UIScreen.main.bounds.width*4/5, minHeight: 50)
                .background(Color.brown)
                .cornerRadius(25)
                .padding(.horizontal)
            }
        }
    }
    
    func closeAlarm() {
        presentationMode.wrappedValue.dismiss()
        print("Alarm closing")
    }
}

#Preview {
    AlarmView()
}
