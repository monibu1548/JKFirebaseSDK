//
//  FirebaseFirestore.swift
//  JKFirebaseSDK
//
//  Created by 정진규 on 2020/06/19.
//

import Foundation
import FirebaseFirestore
 
public enum FirestoreError: Error {
    case defaultError(_ message: String?)
}

public typealias DocumentKey = String

public enum Query {
    case orderDescending(_ key: String)
    case orderAscending(_ key: String)
    case isEqual(_ key: String, target: Any)
    case isGreaterThan(_ key: String, target: Any)
    case isLessThan(_ key: String, target: Any)
    case isGreaterThanOrEqualTo(_ key: String, target: Any)
    case isLessThanOrEqualTo(_ key: String, target: Any)
    case arrayContains(_ key: String, target: Any)
}

public class FirebaseFirestore {
    public static let shared = FirebaseFirestore()
    
    private var reference: DocumentReference {
        #if DEBUG
        return Firestore.firestore().collection("environment").document("development")
        #else
        return Firestore.firestore().collection("environment").document("production")
        #endif
    }
    
    public func insert<T: Encodable>(key: String, object: T, withID: Bool = false, completion: @escaping (Result<DocumentKey, FirestoreError>) -> ()) {
        guard let dict = object.toDictionary() else {
            completion(.failure(.defaultError("encoding error")))
            return
        }

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        var documentReference: DocumentReference?
        var isSuccess = false
        DispatchQueue.global().async { [weak self] in
            documentReference = self?.reference.collection(key).addDocument(data: dict) { (error) in
                isSuccess = (error == nil)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .global()) {
            if withID, isSuccess, let documentID = documentReference?.documentID {
                documentReference?.setData(["id": documentID], merge: true, completion: { (error) in
                    if error != nil {
                        completion(.failure(.defaultError("insert ID fail")))
                        return
                    }
                    completion(.success(documentID))
                    return
                })
            } else {
                guard let documentID = documentReference?.documentID, isSuccess else {
                    completion(.failure(.defaultError("insert fail")))
                    return
                }
                completion(.success(documentID))
                return
            }
        }
    }
    
    public func update(key: String, id: String, object: Encodable, completion: @escaping (Result<Void, FirestoreError>) -> ()) {
        guard let dict = object.toDictionary() else {
            completion(.failure(.defaultError("encoding error")))
            return
        }

        
        reference.collection(key).document(id).updateData(dict) { (error) in
            if let error = error {
                completion(.failure(.defaultError(error.localizedDescription)))
                return
            }
            completion(.success(Void()))
            return
        }
    }
    
    public func upsertDocumentField(key: String, id: String, data: [String: Any], completion: @escaping (Result<Void, FirestoreError>) -> ()) {
        reference.collection(key).document(id).setData(data, merge: true) { (error) in
            if let error = error {
                completion(.failure(.defaultError(error.localizedDescription)))
                return
            }
            completion(.success(Void()))
            return
        }
    }

    public func delete(key: String, id: String, completion: @escaping (Result<Void, FirestoreError>) -> ()) {
        reference.collection(key).document(id).delete { (error) in
            if let error = error {
                completion(.failure(.defaultError(error.localizedDescription)))
                return
            }
            completion(.success(Void()))
            return
        }
    }
    
    public func read<T: Decodable>(key: String, id: String, type: T.Type, completion: @escaping (Result<T, FirestoreError>) -> ()) {
        reference.collection(key).document(id).getDocument { (snapshot, error) in
            guard error == nil else {
                completion(.failure(.defaultError(error.debugDescription)))
                return
            }
            
            guard let snapshotData = snapshot?.data(),
                let data = try? JSONSerialization.data(withJSONObject: snapshotData) else {
                completion(.failure(.defaultError("snapshot is empty")))
                return
            }
            
            guard let value = try? JSONDecoder().decode(T.self, from: data) else {
                completion(.failure(.defaultError("cannot parsing")))
                return
            }
            
            completion(.success(value))
        }
    }
    
    public func list<T: Decodable>(key: String, queries: [Query], limit: Int, latestKey: String?, type: T.Type, completion: @escaping (Result<[T], FirestoreError>) -> ()) {
        
        // 페이징
        if let latestKey = latestKey {
            reference.collection(key).document(latestKey).getDocument { [weak self] (snapshot, error) in
                guard let reference = self?.reference,
                    let snapshot = snapshot else {
                        completion(.failure(.defaultError("cannot find latest key")))
                        return
                }

                var queryRef = reference.collection(key).limit(to: limit)
                for query in queries {
                    switch query {
                    case let .orderDescending(key):
                        queryRef = queryRef.order(by: key, descending: true)
                    case let .orderAscending(key):
                        queryRef = queryRef.order(by: key, descending: false)
                    case let .isEqual(key, target):
                        queryRef = queryRef.whereField(key, isEqualTo: target)
                    case let .isGreaterThan(key, target):
                        queryRef = queryRef.whereField(key, isGreaterThan: target)
                    case let .isLessThan(key, target):
                        queryRef = queryRef.whereField(key, isLessThan: target)
                    case let .isGreaterThanOrEqualTo(key, target):
                        queryRef = queryRef.whereField(key, isGreaterThanOrEqualTo: target)
                    case let .isLessThanOrEqualTo(key, target):
                        queryRef = queryRef.whereField(key, isLessThanOrEqualTo: target)
                    case let .arrayContains(key, target):
                        queryRef = queryRef.whereField(key, arrayContains: target)
                    }
                }

                queryRef.start(afterDocument: snapshot).getDocuments { (snapshot, error) in
                    guard error == nil else {
                        completion(.failure(.defaultError(error.debugDescription)))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion(.failure(.defaultError("snapshot documents are empty")))
                        return
                    }
                    
                    let values = documents
                        .map { $0.data() }
                        .compactMap { try? JSONSerialization.data(withJSONObject: $0) }
                        .compactMap { try? JSONDecoder().decode(T.self, from: $0) }
                    
                    completion(.success(values))
                    return
                }
            }
            return
        }

        // 페이징 없는 경우
        var queryRef = reference.collection(key).limit(to: limit)
        for query in queries {
            switch query {
            case let .orderDescending(key):
                queryRef = queryRef.order(by: key, descending: true)
            case let .orderAscending(key):
                queryRef = queryRef.order(by: key, descending: false)
            case let .isEqual(key, target):
                queryRef = queryRef.whereField(key, isEqualTo: target)
            case let .isGreaterThan(key, target):
                queryRef = queryRef.whereField(key, isGreaterThan: target)
            case let .isLessThan(key, target):
                queryRef = queryRef.whereField(key, isLessThan: target)
            case let .isGreaterThanOrEqualTo(key, target):
                queryRef = queryRef.whereField(key, isGreaterThanOrEqualTo: target)
            case let .isLessThanOrEqualTo(key, target):
                queryRef = queryRef.whereField(key, isLessThanOrEqualTo: target)
            case let .arrayContains(key, target):
                queryRef = queryRef.whereField(key, arrayContains: target)
            }
        }

        queryRef.getDocuments { (snapshot, error) in
            guard error == nil else {
                completion(.failure(.defaultError(error.debugDescription)))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.failure(.defaultError("snapshot documents are empty")))
                return
            }
            
            let values = documents
                .map { $0.data() }
                .compactMap { try? JSONSerialization.data(withJSONObject: $0) }
                .compactMap { try? JSONDecoder().decode(T.self, from: $0) }
            
            completion(.success(values))
            return
        }
    }
}

extension Encodable {
    fileprivate func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }

        guard let dict = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String : Any] else {
            return nil
        }
        
        return dict
    }
}
