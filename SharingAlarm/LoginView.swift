//
//  LoginView.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/3/14.
//

import SwiftUI
import AuthenticationServices
import CloudKit

class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var authViewModel: AuthViewModel
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            UserDefaults.standard.set(appleIDCredential.user, forKey: "appleIDUser")
            authViewModel.fetchUserByAppleID { record, error in
                DispatchQueue.main.async { [self] in
                    guard error == nil && record != nil else  {
                        print("Fetch error: \(error?.localizedDescription ?? "Record is empty")")
                        return
                    }
                    let name = record!["name"] as? String ?? "Unknown"
                    let uid = record!["uid"] as? String ?? "Unknown"
                    UserDefaults.standard.set(name, forKey: "name")
                    UserDefaults.standard.set(uid, forKey: "uid")
                    self.authViewModel.user?.name = name
                    self.authViewModel.user?.uid = uid
                }
            }
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
    var initialUsername: String
    var initialUid: String
        
    @State private var username: String = ""
    @State private var uid: String = ""
    @State private var isChecking = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var usernameWarning: String?
    @State private var uidWarning: String?
    
    init(onSubmit: @escaping (String, String) -> Void, initialUsername: String, initialUid: String) {
        self.onSubmit = onSubmit
        self.initialUsername = initialUsername
        self.initialUid = initialUid
        _username = State(initialValue: initialUsername)
        _uid = State(initialValue: initialUid)
    }
    
    func isUniqueIdentifier(_ identifier: String, completion: @escaping (Bool) -> Void) {
        let predicate = NSPredicate(format: "uid == %@", identifier)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let records = records, !records.isEmpty {
                    // Identifier exists, hence not unique
                    completion(false)
                } else {
                    // No existing record with the identifier, hence unique
                    completion(true)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            // Welcome Text at the top
            Text("Hi, enter your name and your unique identifier to let your friends find you!")
                .font(.title)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 50)
            
            Spacer()
            
            // Username TextField
            TextField("Name", text: $username)
                .textFieldStyle(LargeTextFieldStyle())
                .padding(.horizontal)
            if let usernameWarning = usernameWarning {
                Text(usernameWarning)
                    .foregroundColor(.red)
            }
            // Unique Identifier TextField
            TextField("Unique Identifier", text: $uid)
                .textFieldStyle(LargeTextFieldStyle())
                .padding(.horizontal)
            if let uidWarning = uidWarning {
                Text(uidWarning)
                    .foregroundColor(.red)
            }
            
            Spacer()
            Button(action: validateAndSubmit, label: {
                Text("Go")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
            })
            .background(Color.blue)
            .cornerRadius(25)
            .padding(.horizontal)
            .padding(.bottom, 50)
            
        }
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.all)
    }
    
    private func validateAndSubmit() {
        // Reset warnings
        usernameWarning = nil
        uidWarning = nil
        
        var isValid = true
        
        // Check for empty fields
        if username.isEmpty {
            print("Name cannot be empty")
            usernameWarning = "Name cannot be empty"
            isValid = false
        }
        
        if uid.isEmpty {
            print("Unique Identifier cannot be empty")
            uidWarning = "Unique Identifier cannot be empty"
            isValid = false
        } else if uid != initialUid {
            // Additional check if UID is changed and needs to be unique
            isUniqueIdentifier(uid) { isUnique in
                if !isUnique {
                    uidWarning = "Someone else has taken this UID, think about another one"
                    isValid = false
                } else {
                    // Proceed with submission if both checks pass
                    if isValid {
                        onSubmit(username, uid)
                    }
                }
            }
        } else {
            print("UID Unchanged")
            // UID not changed, proceed if username check passes
            if isValid {
                onSubmit(username, uid)
            }
        }
    }
}

func updateUserRecord(_ record: CKRecord, completion: @escaping () -> Void) {
    // Similar to the save logic in `saveUserProfileToCloudKit`
    // but use the passed `record` instead of creating a new CKRecord
    CKContainer.default().publicCloudDatabase.save(record) { savedRecord, error in
        if let error = error {
            print("Update error: \(error.localizedDescription)")
        } else {
            print("User updated successfully")
        }
        completion()
    }
}

func saveUserProfileToCloudKit(username: String, uid: String, completion: @escaping () -> Void) {
    let newRecord = CKRecord(recordType: "UserData")
    newRecord["appleIDCredential"] = UserDefaults.standard.value(forKey: "appleIDUser") as! String
    newRecord["name"] = username
    newRecord["uid"] = uid
    UserDefaults.standard.set(username, forKey: "name")
    UserDefaults.standard.set(uid, forKey: "uid")
    print("Add to cloud")
    
    CKContainer.default().publicCloudDatabase.save(newRecord) { record, error in
        if let error = error {
            print("An error occurred: \(error.localizedDescription)")
            return
        }
    }
    completion()
}
