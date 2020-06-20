//
//  SignViewController.swift
//  JKFirebaseSDK_Example
//
//  Created by 정진규 on 2020/06/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AuthenticationServices
import JKFirebaseSDK
import FBSDKLoginKit

class SignViewController: FirebaseAuthenticationViewController {
    @IBOutlet weak var facebookLoginButton: FBLoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        facebookLoginButton.delegate = FirebaseAuthentication.shared
        signInWithAppleButton.addTarget(self, action: #selector(signInWithApple), for: .touchUpInside)
    }
    
    @IBAction override func didTappedSignInWithAnonymous() {
        super.didTappedSignInWithAnonymous()
    }
    
    @IBOutlet weak var signInWithAppleButton: ASAuthorizationAppleIDButton!

    @objc func signInWithApple() {
        super.didTappedSignInWithAppleID()
    }
    
    @IBAction override func didTappedSignInWithGoogle() {
        super.didTappedSignInWithGoogle()
    }
}
