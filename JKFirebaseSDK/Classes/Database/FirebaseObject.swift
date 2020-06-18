//
//  FirebaseObject.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/20.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import Foundation

class FirebaseObject: Decodable {
    var key: String? = nil
    var exceptionKeys: [String]? = nil
}

// Enum -> String을 위한 Protocol
// Enum은 EnumForFirebaseObject과 String을 상속받고 valueForDict에 rawValue를 리턴해야한다.
protocol EnumForFirebaseObject {
    var valueForDict: String { get }
}

extension FirebaseObject {
    func asDict() -> [String: Any] {
        var dict = [String: Any]()
        let otherSelf = Mirror(reflecting: self)
        for child in otherSelf.children {
            if let key = child.label, !(exceptionKeys?.contains(key) ?? false) {
                if let enumValue = child.value as? EnumForFirebaseObject {
                    dict[key] = enumValue.valueForDict
                } else if let dateValue = child.value as? Date {
                    dict[key] = Int(dateValue.timeIntervalSince1970)
                } else {
                    dict[key] = child.value
                }
            }
        }
        return dict
    }
}
