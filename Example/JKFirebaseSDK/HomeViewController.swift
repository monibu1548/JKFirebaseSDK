//
//  HomeViewController.swift
//  JKFirebaseSDK_Example
//
//  Created by 정진규 on 2020/06/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import JKFirebaseSDK
import FBSDKLoginKit

class HomeViewController: UIViewController {

    @IBOutlet weak var facebookLoginButton: FBLoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        facebookLoginButton.delegate = FirebaseAuthentication.shared
    }
    
    @IBAction func linkGoogleTapped(_ sender: Any) {
        FirebaseAuthentication.shared.signInWithGoogle(from: self)
    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        FirebaseAuthentication.shared.signOut()
    }
}
