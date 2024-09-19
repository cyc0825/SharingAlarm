//
//  FeedbackView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/19.
//

import SwiftUI

struct FeedbackView: View {
    @State var feedback: String = ""
    @State var uploadSuccess: Bool = false
    var body: some View {
        Form {
            Section(header: Text("Feedback")) {
                TextField("Feedback", text: $feedback, axis: .vertical)
                            .lineLimit(5, reservesSpace: true)
            }
            Button{
                uploadSuccess = true
            } label: {
                Text("Send Feedback")
            }
            
        }
        .alert(isPresented: $uploadSuccess) {
            .init(title: Text("Success"),
                  message: Text("Successfully Sent Feed back"),
                  dismissButton: .default(Text("Confirm"), action: {
                uploadSuccess = false
            }))
        }
    }
}

#Preview {
    FeedbackView()
}
