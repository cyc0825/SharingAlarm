//
//  CoinEarnedPopupCard.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/9/11.
//

import SwiftUI

struct CoinEarnedPopupCard: View {
    @Binding var isVisible: Bool
    let coinsEarned: Int
    
    var body: some View {
        VStack {
            if isVisible {
                Text("You earned \(coinsEarned) coins!")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.5), value: isVisible)
                    .onAppear {
                        // Automatically hide the popup after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isVisible = false
                            }
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 50) // Adjust the top padding to control the popup position
    }
}


struct CoinEarnedPopupCard_Previews: PreviewProvider {
    @State static var isVisible = true
    static var previews: some View {
        CoinEarnedPopupCard(isVisible: $isVisible, coinsEarned: 20)
    }
}
