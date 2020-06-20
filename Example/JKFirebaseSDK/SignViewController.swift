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

class SignViewController: FirebaseAuthenticationViewController {
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        signInWithAppleButton.addTarget(self, action: #selector(signInWithApple), for: .touchUpInside)
    }
}
