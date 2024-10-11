//
//  VerifyPhoneNumberView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/10/9.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

private enum FocusableField: Hashable {
  case phoneNumber
  case code
}

struct VerifyPhoneNumberView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var selection = 0 // To track the current page in TabView
    @State private var codeDigits = Array(repeating: "", count: 6)
    @FocusState private var focusedField: Int?
    @State private var remainingTime = 0 // Countdown for resend
    @State private var timer: Timer? // Timer to handle countdown
    
    private func signInWithPhoneNumber() {
        print("verify phone number tapped")
        Task {
            if await authViewModel.signInWithPhoneNumber(smsCode: codeDigits.joined()) == true {
                dismiss()
            }
        }
    }
    
    private func sentVerificationCode(phoneNumber: String) {
        print("Send verification code to \(phoneNumber)")
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                // Sign in using the verificationID and the code sent to the user
                // ...
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            }
    }
    
    var body: some View {
        VStack {
            TabView(selection: $selection) {
                // Phone Number Input Page
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "phone")
                        Text("+1")
                        TextField("(XXX) XXX-XXXX", text: $authViewModel.phoneNumber)
                            .onChange(of: authViewModel.phoneNumber) { newValue in
                                let formattedNumber = newValue.formatPhoneNumber()
                                if formattedNumber != newValue {
                                    authViewModel.phoneNumber = formattedNumber
                                }
                            }
                            .accentColor(.thirdAccent)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    .background(Capsule()
                        .fill(.secondAccent.opacity(0.4)))
                    
                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        withAnimation {
                            sentVerificationCode(phoneNumber: "+1\(extractDigits(authViewModel.phoneNumber))")
                            selection = 1 // Move to the SMS code input page
                            focusedField = 1 // Focus first SMS code field
                            startTimer()
                        }
                    } label: {
                        Text(remainingTime > 0 ? "Send(\(remainingTime))" : "Send")
                            .foregroundStyle(.systemText)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(extractDigits(authViewModel.phoneNumber).count != 10 || remainingTime > 0)
                    .padding()
                    .background(Capsule().fill(.secondAccent))
                    .opacity((extractDigits(authViewModel.phoneNumber).count != 10 || remainingTime > 0) ? 0.5 : 1.0)
                }
                .tag(0) // Tag for the first tab (Phone Number Page)
                .gesture(DragGesture())
                
                // SMS Code Input Page
                VStack {
                    HStack(spacing: 10) {
                        ForEach(0..<6) { index in
                            TextField("", text: $codeDigits[index])
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(.secondAccent.opacity(0.5)))
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: index + 1) // Focus the correct field
                                .onChange(of: codeDigits[index]) { newValue in
                                    handleFieldInput(for: index, with: newValue)
                                }
                                .onTapGesture {
                                    if index == 0 { // Only allow tapping the first field
                                        focusedField = 1
                                    }
                                }
                        }
                    }
                    .contentShape(Rectangle()) // Make the entire HStack tappable
                    .onTapGesture {
                        focusedField = 1 // Start focus from the first digit field when tapped
                    }
                    .padding(.bottom)
                    
                    Button {
                        signInWithPhoneNumber() // Function to handle sign-in
                    } label: {
                        if authViewModel.authenticationState != .authenticating {
                            Text("Verify")
                                .foregroundStyle(.systemText)
                                .frame(maxWidth: .infinity)
                        } else {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Capsule().fill(.secondAccent))
                    .opacity(!isCodeComplete() ? 0.5 : 1)
                    .disabled(!isCodeComplete())
                }
                .tag(1) // Tag for the second tab (SMS Code Input Page)
            }
            .frame(height: 160)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            HStack {
                Text("Try Account login?")
                Button(action: { authViewModel.switchFlow(.login) }) {
                    Text("Switch to account login")
                        .fontWeight(.semibold)
                        .foregroundColor(.secondAccent)
                }
            }
            .padding([.top, .bottom], 50)
        }
        .onTapGesture {
            self.dismissKeyboard()
        }
    }
    
    private func handleFieldInput(for index: Int, with newValue: String) {
        if newValue.count > 1 {
            // Handle paste scenario by splitting the input
            let digits = Array(newValue.prefix(6)) // Take the first 6 characters
            for i in 0..<digits.count {
                codeDigits[i] = String(digits[i])
            }
            // Move focus to the last filled field or unfocus if done
            focusedField = digits.count == 6 ? nil : digits.count + 1
        } else if newValue.count == 1 {
            // Normal single-digit entry, move to the next field
            if index < 5 {
                focusedField = index + 2
            } else {
                focusedField = nil // Unfocus when all fields are filled
            }
        } else if newValue.isEmpty {
            // Handle backspace: move focus to the previous field
            if index > 0 {
                focusedField = index
            }
        }
    }
    
    private func isCodeComplete() -> Bool {
        return codeDigits.allSatisfy { !$0.isEmpty }
    }
    
    private func startTimer() {
        remainingTime = 60
        timer?.invalidate() // Invalidate any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                timer?.invalidate() // Stop the timer when it reaches zero
            }
        }
    }

    // Function to extract digits and store the raw number without formatting
    private func extractDigits(_ formattedNumber: String) -> String {
        return formattedNumber.filter { "0123456789".contains($0) }
    }
    
    // Function to dismiss the keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    VerifyPhoneNumberView()
        .environmentObject(AuthViewModel())
}
