//
//  RootWindow.swift
//  AlarmPill
//
//  Created by JingyuJung on 2019/11/18.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import UIKit
import Firebase
import JKExtension
import JKFirebaseSDK

enum RootViewControllerType {
    case login
    case main
}

class RootWindow: UIWindow {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let viewController: UIViewController

        if let user = Auth.auth().currentUser {
            viewController = HomeViewController.instanceFromStoryboard()
        } else {
            viewController = SignViewController.instanceFromStoryboard()
        }
        
        rootViewController = viewController
        makeKeyAndVisible()

        addNotificationCenter()
    }
    
    private func addNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(moveToMainView), name: FirebaseAuthenticationNotification.signInSuccess.notificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(moveToLoginView), name: FirebaseAuthenticationNotification.signOutSuccess.notificationName, object: nil)
    }

    @objc private func moveToLoginView() {
        changeRootView(.login)
    }

    @objc private func moveToMainView() {
        registerFCMToken()
        changeRootView(.main)
    }

    private func changeRootView(_ type: RootViewControllerType) {
        let viewController: UIViewController
        switch type {
        case .login:
            viewController = SignViewController.instanceFromStoryboard()
        case .main:
            viewController = HomeViewController.instanceFromStoryboard()
        }
        rootViewController = viewController
    }

    @objc private func registerFCMToken() {
        InstanceID.instanceID().instanceID { (result, error) in
            if let token = result?.token, let uid = FirebaseAuthentication.shared.currentUser()?.uid {
                // Server.shared.updateFCMToken(uid: uid, token: token).subscribe().dispose()
            }
        }
    }
}
