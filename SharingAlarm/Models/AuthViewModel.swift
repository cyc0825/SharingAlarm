//
//  AuthViewModel.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/8.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// For Sign in with Apple
import AuthenticationServices
import CryptoKit

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum AuthenticationFlow {
  case login
  case signUp
}

enum EmailLinkStatus {
  case none
  case pending
}

@MainActor
class AuthViewModel: ObservableObject {
    @AppStorage("email-link") var emailLink: String?
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    
    @Published var flow: AuthenticationFlow = .login
    
    @Published var isValid = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var errorMessage = ""
    @Published var user: User?
    @Published var displayName = ""
    
    @Published var isNewUser = false
    @Published var isGuestUser = false
    @Published var isVerified = false
    
    private var currentNonce: String?
    
    init() {
        registerAuthStateHandler()
        verifySignInWithAppleAuthenticationState()
        
        $flow
            .combineLatest($email, $password, $confirmPassword)
            .map { flow, email, password, confirmPassword in
                flow == .login
                ? !(email.isEmpty || password.isEmpty)
                : !(email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
            }
            .assign(to: &$isValid)
        
        $user
            .compactMap { user in
                user?.isAnonymous
            }
            .assign(to: &$isGuestUser)
        
        $user
            .compactMap { user in
                user?.isEmailVerified
            }
            .assign(to: &$isVerified)
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                self.authenticationState = user == nil ? .unauthenticated : .authenticated
                self.displayName = user?.displayName ?? user?.email ?? ""
            }
        }
    }
    
    func switchFlow() {
        flow = flow == .login ? .signUp : .login
        errorMessage = ""
    }
    
    private func wait() async {
        do {
            print("Wait")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            print("Done")
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    
    func reset() {
      flow = .login
      email = ""
      emailLink = nil
      errorMessage = ""
    }
}

// MARK: - Email and Password Authentication

extension AuthViewModel {
    func signInWithEmailPassword() async -> Bool {
        authenticationState = .authenticating
        do {
            print("Authenting")
            let authResult = try await Auth.auth().signIn(withEmail: self.email, password: self.password)
            user = authResult.user
            if authResult.additionalUserInfo?.isNewUser == true {
                self.isNewUser = true
//                await createUserDocument(userID: authResult.user.uid, name: nil, uid: nil)
            }
            print("User \(authResult.user.uid) signed in")
            return true
        }
        catch  {
            print(error)
            errorMessage = error.localizedDescription
            authenticationState = .unauthenticated
            return false
        }
    }
    
    func signUpWithEmailPassword() async -> Bool {
        authenticationState = .authenticating
        do  {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            user = authResult.user
            if authResult.additionalUserInfo?.isNewUser == true {
                isNewUser = true
                // await createUserDocument(userID: authResult.user.uid, name: nil, uid: nil)
            }
            print("User \(authResult.user.uid) created and signed in")
            return true
        }
        catch {
            print(error)
            errorMessage = error.localizedDescription
            authenticationState = .unauthenticated
            return false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        }
        catch {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    
    
    func deleteAccount() async -> Bool {
        guard let user = user else { return false }
        guard let lastSignInDate = user.metadata.lastSignInDate else { return false }
        let needsReauth = !lastSignInDate.isWithinPast(minutes: 5)
        
        let needsTokenRevocation = user.providerData.contains { $0.providerID == "apple.com" }
        
        do {
            if needsReauth || needsTokenRevocation {
                let signInWithApple = SignInWithApple()
                let appleIDCredential = try await signInWithApple()
                
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetdch identify token.")
                    return false
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                    return false
                }
                
                let nonce = randomNonceString()
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
                
                if needsReauth {
                    try await user.reauthenticate(with: credential)
                }
                if needsTokenRevocation {
                    guard let authorizationCode = appleIDCredential.authorizationCode else { return false }
                    guard let authCodeString = String(data: authorizationCode, encoding: .utf8) else { return false }
                    
                    try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
                }
            }
            
            try await user.delete()
            errorMessage = ""
            return true
        }
        catch {
            print(error)
            errorMessage = error.localizedDescription
            return false
        }
    }
}

// MARK: Sign in with Apple
class SignInWithApple: NSObject, ASAuthorizationControllerDelegate {
    
    private var continuation : CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    
    func callAsFunction() async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.performRequests()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if case let appleIDCredential as ASAuthorizationAppleIDCredential = authorization.credential {
            continuation?.resume(returning: appleIDCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
    }
}

extension AuthViewModel {
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        if case .failure(let failure) = result {
            errorMessage = failure.localizedDescription
        }
        else if case .success(let authorization) = result {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: a login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetdch identify token.")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
                Task {
                    do {
                        let authResult = try await Auth.auth().signIn(with: credential)
                        if authResult.additionalUserInfo?.isNewUser == true {
                            
                            self.isNewUser = true
//                            createUserDocument(userID: authResult.user.uid, name: nil, uid: nil)
                        }
                    }
                    catch {
                        print("Error authenticating: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func createUserDocument(userID: String, name: String?, uid: String?) {
        let db = Firestore.firestore()
        let userDocument = db.collection("UserData").document(userID)
        
        // Set initial data for the new user
        let userData = [
            "name": name ?? "Unknown",
            "uid": uid ?? "Unknown"
        ]
        Task {
            do {
                try await userDocument.setData(userData)
                print("User document created or updated successfully.")
            } catch let error {
                print("Error creating user document: \(error)")
            }
        }
    }
    
    func updateDisplayName(for user: User, with appleIDCredential: ASAuthorizationAppleIDCredential, force: Bool = false) async {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            // current user is non-empty, don't overwrite it
        }
        else {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = appleIDCredential.displayName()
            do {
                try await changeRequest.commitChanges()
                self.displayName = Auth.auth().currentUser?.displayName ?? ""
            }
            catch {
                print("Unable to update the user's displayname: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func verifySignInWithAppleAuthenticationState() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = Auth.auth().currentUser?.providerData
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            Task {
                do {
                    let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                    switch credentialState {
                    case .authorized:
                        break // The Apple ID credential is valid.
                    case .revoked, .notFound:
                        // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                        self.signOut()
                    default:
                        break
                    }
                }
                catch {
                }
            }
        }
    }
}

extension ASAuthorizationAppleIDCredential {
  func displayName() -> String {
    return [self.fullName?.givenName, self.fullName?.familyName]
      .compactMap( {$0})
      .joined(separator: " ")
  }
}

// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                )
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

private func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashedData = SHA256.hash(data: inputData)
  let hashString = hashedData.compactMap {
    String(format: "%02x", $0)
  }.joined()

  return hashString
}

// MARK: - Email and Link Authentication

extension AuthViewModel {
    func sendSignInLink() async {
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.url = URL(string: "https://sharingalarm.page.link/email-link-login")
        
        do {
            try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)
            emailLink = email
        }
        catch {
            print(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    var emailLinkStatus: EmailLinkStatus {
        emailLink == nil ? .none : .pending
    }
    
    func handleSignInLink(_ url: URL) async {
        guard let email = emailLink else {
            errorMessage = "Invalid email address. Most likely, the link you used has expired. Try signing in again."
            return
        }
        let link = url.absoluteString
        if Auth.auth().isSignIn(withEmailLink: link) {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, link: link)
                let user = result.user
                print("User \(user.uid) signed in with email \(user.email ?? "(unknown)"). The email is \(user.isEmailVerified ? "" : "NOT") verified")
                emailLink = nil
            }
            catch {
                print(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

extension Date {
    func isWithinPast(minutes: Int) -> Bool {
        let now = Date.now
        let timeAgo = Date.now.addingTimeInterval(-1 * TimeInterval(60 * minutes))
        let range = timeAgo...now
        return range.contains(self)
    }
}
