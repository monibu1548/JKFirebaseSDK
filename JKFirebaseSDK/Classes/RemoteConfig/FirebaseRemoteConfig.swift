//
//  FirebaseRemoteConfig.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/19.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

public class FirebaseRemoteConfig {
    public static let shared = FirebaseRemoteConfig()

    private let remoteConfig = RemoteConfig.remoteConfig()
    private init() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 60 * 60
        #endif
        remoteConfig.configSettings = settings
    }

    public func initialize(completion: @escaping (_ success: Bool)->()) {
        remoteConfig.fetchAndActivate { (status, error) in
            if error != nil {
                completion(false)
                return
            }
            completion(true)
            return
        }
    }

    public func intValue(key: String) -> Int? {
        guard let value = remoteConfig[key].numberValue?.intValue else {
            return nil
        }
        return value
    }

    public func stringValue(key: String) -> String? {
        return remoteConfig[key].stringValue
    }

    public func doubleValue(key: String) -> Double? {
        guard let value = remoteConfig[key].numberValue?.doubleValue else {
            return nil
        }
        return value
    }
}
