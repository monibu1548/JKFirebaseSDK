//
//  FirebaseAuthenticationViewController.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/18.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import UIKit

open class FirebaseAuthenticationViewController: UIViewController {
    @IBAction open func didTappedSignInWithAppleID() {
        FirebaseAuthentication.shared.signInWithApple()
    }

    @IBAction open func didTappedSignInWithAnonymous() {
        FirebaseAuthentication.shared.signInWithAnonymous()
    }
    
    @IBAction open func didTappedSignInWithGoogle() {
        FirebaseAuthentication.shared.signInWithGoogle(from: self)
    }
}
