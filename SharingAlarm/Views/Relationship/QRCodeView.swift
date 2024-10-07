//
//  QRCodeView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/10/6.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    var uid: String = UserDefaults.standard.string(forKey: "uid") ?? ""
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        ZStack {
            Image("QRCodeBG")
                .blur(radius: 30)
            Rectangle()
                .frame(width: 300, height: 400)
                .background(.thinMaterial)
                .cornerRadius(10)
            if let qrCodeImage = generateQRCode(from: "SharingAlarm://addFriend?uid=\(uid)") {
                VStack(alignment: .center) {
                    Image(uiImage: qrCodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    Text("Scan this QR Code to be friends with me")
                        .font(.headline)
                        .frame(width: 250)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("Failed to generate QR Code")
            }
        }
    }

    func generateQRCode(from string: String) -> UIImage? {
       let data = Data(string.utf8)
       filter.setValue(data, forKey: "inputMessage")
       
       guard let outputImage = filter.outputImage else { return nil }

       // Define brown color
        let QRcodeColor = CIColor(color: UIColor.systemText)

       // Apply color filter for the QR code
       let colorFilter = CIFilter.falseColor()
       colorFilter.inputImage = outputImage
       colorFilter.color0 = QRcodeColor // Foreground color (QR code itself)
       colorFilter.color1 = .clear // Background color (transparent)

       if let coloredOutputImage = colorFilter.outputImage,
          let cgImage = context.createCGImage(coloredOutputImage, from: coloredOutputImage.extent) {
           return UIImage(cgImage: cgImage)
       }

       return nil
   }
}

struct QRScanResultView: View {
    @StateObject var friendViewModel: FriendsViewModel
    @Environment(\.dismiss) var dismiss
    var user2ID: String
    var body: some View {
        VStack {
            Text("Are you sure you want to send friend request to @\(user2ID)? ")
                .multilineTextAlignment(.center)
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                Button("Send") {
                    friendViewModel.saveFriendRequest(user2ID: user2ID)
                    dismiss()
                }.buttonStyle(.borderedProminent)
                    .padding()
            }
            .padding()
        }
        .padding()
        .presentationDetents([.fraction(0.3)])
    }
}

#Preview {
    QRScanResultView(friendViewModel: .init(), user2ID: "user2ID")
}
