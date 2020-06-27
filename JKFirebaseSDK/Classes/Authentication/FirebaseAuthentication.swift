//
//  FirebaseAuthentication.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/18.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import Foundation
import GoogleSignIn
import AuthenticationServices
import FirebaseAuth
import CommonCrypto
import FirebaseCore
import FBSDKLoginKit

public struct JKUser: Codable {
    public let id: String
    public let displayName: String?
    public let email: String?
    public let phoneNumber: String?
    public let photoURL: String?
}

public enum FirebaseAuthenticationNotification: String {
    case signOutSuccess
    case signOutError
    case signInSuccess
    case signInError
    case linkUserSuccess
    case linkUserError
    
    public var notificationName: NSNotification.Name {
        return NSNotification.Name(rawValue: self.rawValue)
    }
}

public class FirebaseAuthentication: NSObject, GIDSignInDelegate, LoginButtonDelegate {
    public static let shared = FirebaseAuthentication()

    fileprivate var currentNonce: String?
    
    private override init() {}
    
    public func currentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    public func signUpWithEmail(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let user = authResult?.user, error == nil else {
                self?.postNotificationSignInError()
                return
            }
            self?.registerUser(user: user)
            self?.postNotificationSignInSuccess()
        }
    }
    
    public func signInWithGoogle(from: UIViewController) {
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = from
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    // 구글 로그인 Callback
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let _ = error {
            postNotificationSignInError()
            return
        }

        guard let authentication = user.authentication else {
            postNotificationSignInError()
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)

        link(credential: credential)
    }
    
    private func link(credential: AuthCredential) {
        if let user = Auth.auth().currentUser {
            user.link(with: credential) { [weak self] (authResult, error) in
                guard let _ = authResult?.user, error == nil else {
                    self?.postNotificationLinkUserError()
                    return
                }
                self?.postNotificationLinkUserSuccess()
            }
        } else {
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                guard let user = authResult?.user, error == nil else {
                    self?.postNotificationSignInError()
                    return
                }
                self?.registerUser(user: user)
                self?.postNotificationSignInSuccess()
            }
        }
    }
    
    // Facebook Delegate
    public func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if error == nil, let tokenString = result?.token?.tokenString {
            let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)
            link(credential: credential)
        }
    }
    
    // Facebook Delegate
    public func loginButtonDidLogOut(_ loginButton: FBLoginButton) {}

    public func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let user = authResult?.user, error == nil else {
                self?.postNotificationSignInError()
                return
            }
            self?.registerUser(user: user)
            self?.postNotificationSignInSuccess()
        }
    }
    
    public func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    public func signInWithAnonymous() {
        Auth.auth().signInAnonymously() { [weak self] (authResult, error) in
            guard let user = authResult?.user, error == nil else {
                self?.postNotificationSignInError()
                return
            }
            self?.registerUser(user: user)
            self?.postNotificationSignInSuccess()
        }
    }
    
    private func registerUser(user: User) {
        let privateUser = JKUser(id: user.uid, displayName: user.displayName, email: user.email, phoneNumber: user.phoneNumber, photoURL: user.photoURL?.absoluteString)
        
        FirebaseFirestore.shared.insert(key: "user", object: privateUser) { (result) in }
    }
    
    public func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            postNotificationSignOutSuccess()
        } catch {
            postNotificationSignOutError()
        }
    }

    public func deleteUser() {
        let firebaseAuth = Auth.auth()
        firebaseAuth.currentUser?.delete(completion: nil)
    }
}

extension FirebaseAuthentication: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            link(credential: credential)
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        postNotificationSignInError()
    }
}

extension FirebaseAuthentication: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
}

extension FirebaseAuthentication {
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if length == 0 {
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
        let hashedData = hashSHA256(data: inputData)
        let hashString = hashedData!.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func hashSHA256(data:Data) -> Data? {
        var hashData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = hashData.withUnsafeMutableBytes {digestBytes in
            data.withUnsafeBytes {messageBytes in
                CC_SHA256(messageBytes, CC_LONG(data.count), digestBytes)
            }
        }
        return hashData
    }
    
    private func postNotificationSignInSuccess() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.signInSuccess.notificationName, object: nil)
    }
    
    private func postNotificationSignInError() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.signInError.notificationName, object: nil)
    }
    
    private func postNotificationSignOutSuccess() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.signOutSuccess.notificationName, object: nil)
    }
    
    private func postNotificationSignOutError() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.signOutError.notificationName, object: nil)
    }
    
    private func postNotificationLinkUserSuccess() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.linkUserSuccess.notificationName, object: nil)
    }
    
    private func postNotificationLinkUserError() {
        NotificationCenter.default.post(name: FirebaseAuthenticationNotification.linkUserError.notificationName, object: nil)
    }
}
