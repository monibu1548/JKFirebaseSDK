//
//  FirebaseDatabase.swift
//  AlarmPill
//
//  Created by JingyuJung on 2019/11/20.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import Foundation
import FirebaseDatabase

public struct FirebaseDatabaseQuery {
    enum Order {
        case asec
        case desc
    }

    var orderChildKey: String? = nil
    var startKey: Any? = nil
    var endKey: Any? = nil
    var orderByKey: Bool = false

    var order: Order = .asec
    var limitCount: UInt = 20

    public init() {}
}

@available(*, deprecated, message: "Firestore를 이용해주세요")
public class FirebaseDatabase {
    public static let shared = FirebaseDatabase()

    private let database = Database.database().reference()
    private let decoder = JSONDecoder()

    private init() {}

    func loadFirebaseObject<D: FirebaseObject>(path: String, type: D.Type, completion: @escaping (_ object: D?)->()) {
        pathToRef(path).observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard snapshot.exists(),
                let snapShotValue = snapshot.value,
                let data = try? JSONSerialization.data(withJSONObject: snapShotValue) else {
                completion(nil)
                return
            }

            guard let value = try? self?.decoder.decode(type, from: data) else {
                completion(nil)
                return
            }
            completion(value)
        }
    }
    
    func loadObject<D: Decodable>(path: String, type: D.Type, completion: @escaping (_ object: D?)->()) {
        pathToRef(path).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.exists(),
                let snapShotValue = snapshot.value else {
                completion(nil)
                return
            }

            guard let value = snapShotValue as? D else {
                completion(nil)
                return
            }
            completion(value)
        }
    }

    func loadObjects<D: Decodable>(path: String, query: FirebaseDatabaseQuery? = nil, type: D.Type, completion: @escaping (_ object: D?)->()) {
        var path = pathToRef(path).queryOrderedByKey()

        if let query = query {
            if let orderChildKey = query.orderChildKey {
                path = path.queryOrdered(byChild: orderChildKey)
            }
            if let startkey = query.startKey {
                path = path.queryStarting(atValue: startkey)
            }
            if let endKey = query.endKey {
                path = path.queryEnding(atValue: endKey)
            }
            switch query.order {
            case .asec:
                path = path.queryLimited(toFirst: query.limitCount)
            case .desc:
                path = path.queryLimited(toLast: query.limitCount)
            }
        }

        path.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard snapshot.exists(),
                let snapShotValue = snapshot.value,
                let data = try? JSONSerialization.data(withJSONObject: snapShotValue) else {
                completion(nil)
                return
            }

            guard let value = try? self?.decoder.decode(type, from: data) else {
                completion(nil)
                return
            }
            completion(value)
        }
    }

    func loadFirebaseObjects<D: FirebaseObject>(path: String, query: FirebaseDatabaseQuery, type: [D].Type, completion: @escaping (_ object: [D])->()) {
        var databaseQuery: DatabaseQuery
        switch query.order {
        case .asec:
            databaseQuery = pathToRef(path).queryLimited(toFirst: query.limitCount)
        case .desc:
            databaseQuery = pathToRef(path).queryLimited(toLast: query.limitCount)
        }

        if let orderChildKey = query.orderChildKey {
            databaseQuery = databaseQuery.queryOrdered(byChild: orderChildKey)
        }
        if let startkey = query.startKey {
            databaseQuery = databaseQuery.queryStarting(atValue: startkey)
        }
        if let endKey = query.endKey {
            databaseQuery = databaseQuery.queryEnding(atValue: endKey)
        }


        databaseQuery.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            self?.loadObjectsCore(snapshot: snapshot, completion: completion)
        }
    }

    private func loadObjectsCore<D: FirebaseObject>(snapshot: DataSnapshot, completion: @escaping (_ object: [D])->()) {
        var values = [D]()

        guard snapshot.exists(),
            let snapshotValue = snapshot.value,
            let data = try? JSONSerialization.data(withJSONObject: snapshotValue) else {
                completion(values)
            return
        }

        guard let dictionary = try? self.decoder.decode(Dictionary<String, D>.self, from: data) else {
            fatalError()
        }
    
        for (key, value) in dictionary {
            let object = value
            object.key = key
            values.append(object)
        }

        completion(values)
    }

    private func loadObjectsCore<D: Decodable>(snapshot: DataSnapshot, completion: @escaping (_ object: [D])->()) {
        var values = [D]()

        guard snapshot.exists(),
            let snapshotValue = snapshot.value,
            let data = try? JSONSerialization.data(withJSONObject: snapshotValue) else {
                completion(values)
            return
        }

        guard let dictionary = try? self.decoder.decode(Dictionary<String, D>.self, from: data) else {
            fatalError()
        }
    
        for (_, value) in dictionary {
            let object = value
            values.append(object)
        }

        completion(values)
    }

    // Path에 Value를 Set 한다.
    func setFirebaseObject<D: FirebaseObject>(path: String, object: D) {
        pathToRef(path).updateChildValues(object.asDict())
    }

    func setObject<D: Decodable>(path: String, object: D) {
        pathToRef(path).setValue(object)
    }

    // Path에 Value를 추가한다.
    func addFirebaseObject(path: String, object: FirebaseObject) -> String {
        if let key = object.key {
            pathToRef(path).child(key).updateChildValues(object.asDict())
            return key
        } else {
            let childByAutoID = pathToRef(path).childByAutoId()
            childByAutoID.updateChildValues(object.asDict())
            return childByAutoID.url.components(separatedBy: "/").last!
        }
    }

    func addObject<D: Decodable>(path: String, object: D) {
        let childByAutoID = pathToRef(path).childByAutoId()
        childByAutoID.setValue(object)
    }

    func addAuthID(path: String) -> String {
        return pathToRef(path).childByAutoId().url.components(separatedBy: "/").last!
    }

    func delete(path: String, object: FirebaseObject) {
        let deletePath = "\(path)/\(object.key ?? "")"
        pathToRef(deletePath).removeValue()
    }

    func delete(path: String) {
        pathToRef(path).removeValue()
    }

    private func pathToRef(_ routesString : String) -> DatabaseReference {
        let routes = routesString.components(separatedBy: "/").filter { !$0.isEmpty }

        var ref = database
        for route in routes {
            ref = ref.child(route)
        }

        return ref
    }
}
