//
//  FirebaseAuthenticationViewController.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/18.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import UIKit

class FirebaseAuthenticationViewController: UIViewController {
    @IBAction public func didTappedSignInWithAppleID() {
        if #available(iOS 13.0, *) {
            FirebaseAuthentication.shared.signInWithApple()
        } else {
            // Fallback on earlier versions
        }
    }

    @IBAction public func didTappedSignInWithAnonymous() {
        FirebaseAuthentication.shared.signInWithAnonymous()
    }
}
