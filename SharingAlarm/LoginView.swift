//
//  LoginView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import AuthenticationServices
import CloudKit
import Combine

class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var authViewModel: AuthViewModel
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            UserDefaults.standard.set(appleIDCredential.user, forKey: "appleIDUser")
            authViewModel.updateAuthenticationState(isAuthenticated: true)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the current window to present the sign in view
        return UIApplication.shared.windows.first! // Adjust this as necessary for your app structure
    }
}


struct SignInWithAppleButton: UIViewRepresentable {
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        return ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
    }
}

struct LoginView: View {
    @StateObject var authViewModel: AuthViewModel
    @State private var coordinator: Coordinator?
    var body: some View {
        NavigationStack{
            ZStack {
                Color.accentColor.ignoresSafeArea(edges: .all)
                VStack{
                    Image("loginscreen")
                        .resizable()
                        .frame(width: 300, height: 300)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height/3)
                    SignInWithAppleButton()
                        .frame(width: 280, height: 60)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height/4)
                        .onTapGesture {
                            performSignInWithApple()
                        }
                }
                
            }
            .navigationTitle("WELCOME!")
        }
        
    }

    private func performSignInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        coordinator = Coordinator(authViewModel: authViewModel)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = coordinator
        controller.presentationContextProvider = coordinator
        controller.performRequests()
    }
}

struct ProfileSetupView: View {
    var onSubmit: (String, String) -> Void
    
    @State private var username = ""
    @State private var email = ""
    
    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea(edges: .all)
            Form {
                TextField("Username", text: $username)
                TextField("Email", text: $email)
                Button("Submit") {
                    onSubmit(username, email)
                }
                .disabled(username.isEmpty || email.isEmpty)
            }
        }
    }
}

func saveUserProfileToCloudKit(username: String, email: String, completion: @escaping () -> Void) {
    let newRecord = CKRecord(recordType: "UserData")
    newRecord["appleIDCredential"] = UserDefaults.standard.value(forKey: "appleIDUser") as! String
    newRecord["name"] = username
    newRecord["email"] = email
    UserDefaults.standard.set(username, forKey: "name")
    UserDefaults.standard.set(email, forKey: "email")
    print("Add to cloud")
    
    CKContainer.default().publicCloudDatabase.save(newRecord) { record, error in
        if let error = error {
            print("An error occurred: \(error.localizedDescription)")
            return
        }
    }
    completion()
}

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userExists: Bool = false
    @Published var shouldShowProfileSetup: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        isAuthenticated = UserDefaults.standard.bool(forKey: "logged")
        $userExists
            .receive(on: DispatchQueue.main)
            .sink { [weak self] exists in
                self?.updateShowingProfileSetup()
            }
            .store(in: &cancellables)
    }
    
    func updateShowingProfileSetup() {
        // Adjust this logic as needed. This is a simple example.
        shouldShowProfileSetup = isAuthenticated && userExists == false
    }
    
    func updateAuthenticationState(isAuthenticated: Bool) {
        UserDefaults.standard.set(isAuthenticated, forKey: "logged")
        self.isAuthenticated = isAuthenticated
    }
    
    func checkUserExistsWithAppleID(appleID: String) {
        let predicate = NSPredicate(format: "appleIDCredential == %@", appleID)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        let database = CKContainer.default().publicCloudDatabase
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                guard let self = self, error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                if let record = records?.first {
                    self.userExists = true
                    
                    // Assuming 'name' and 'email' are the field names in your CloudKit record.
                    let name = record["name"] as? String ?? "Unknown"
                    let email = record["email"] as? String ?? "Unknown"
                    
                    // Saving to UserDefaults
                    UserDefaults.standard.set(name, forKey: "name")
                    UserDefaults.standard.set(email, forKey: "email")
                    
                } else {
                    self.userExists = false
                }
            }
        }
    }
    
    func setUserExists(_ exists: Bool) {
        DispatchQueue.main.async {
            self.userExists = exists
        }
    }
}
