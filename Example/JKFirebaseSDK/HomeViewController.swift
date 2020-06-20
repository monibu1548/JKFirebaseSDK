//
//  HomeViewController.swift
//  JKFirebaseSDK_Example
//
//  Created by 정진규 on 2020/06/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import JKFirebaseSDK

class HomeViewController: UIViewController {

    @IBAction func linkGoogleTapped(_ sender: Any) {
        FirebaseAuthentication.shared.signInWithGoogle(from: self)
    }
    
    @IBAction func linkAnonymousTapped(_ sender: Any) {
    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        FirebaseAuthentication.shared.signOut()
    }
}
