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
    
    @State private var username: String = ""
    @State private var uid: String = ""
    
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
            
            // Unique Identifier TextField
            TextField("Unique Identifier", text: $uid)
                .textFieldStyle(LargeTextFieldStyle())
                .padding(.horizontal)
            
            Spacer()
            
            // Submit Button
            Button(action: {
                onSubmit(username, uid)
            }) {
                Text("Go")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.all) // Extend the background color to the edges
    }
}

// Custom TextField Style for larger TextFields
struct LargeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
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

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userExists: Bool = false
    @Published var shouldShowProfileSetup: Bool = false
    @Published var user: AppUser?
    
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
    
    func fetchUserByAppleID(completion: @escaping (CKRecord?, Error?) -> Void) {
        
        guard let appleIDCredential = UserDefaults.standard.value(forKey: "appleIDUser") as? String else {
            completion(nil, nil) // No appleIDCredential stored
            return
        }
        let predicate = NSPredicate(format: "appleIDCredential == %@", appleIDCredential)
        let query = CKQuery(recordType: "UserData", predicate: predicate)
        let database = CKContainer.default().publicCloudDatabase
        
        database.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(records?.first, nil) // Assuming only one record per appleIDCredential
        }
    }
    
    // This function is for authorizing when the app is first logged in
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
                    let uid = record["uid"] as? String ?? "Unknown"
                    
                    // Saving to UserDefaults
                    UserDefaults.standard.set(name, forKey: "name")
                    UserDefaults.standard.set(uid, forKey: "uid")
                    
                } else {
                    self.userExists = false
                }
            }
        }
    }
    
    func saveOrUpdateUserProfile(username: String, uid: String, completion: @escaping () -> Void) {
        fetchUserByAppleID { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Fetch error: \(error.localizedDescription)")
                    completion()
                    return
                }
                
                if let existingRecord = record {
                    // Update the existing record
                    existingRecord["name"] = username
                    existingRecord["uid"] = uid
                    updateUserRecord(existingRecord, completion: completion)
                    self.user = AppUser(name: username, uid: uid, authMethod: .apple)
                } else {
                    // No existing record, create a new one
                    self.user = AppUser(name: username, uid: uid, authMethod: .apple)
                    saveUserProfileToCloudKit(username: username, uid: uid, completion: completion)
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
