//
//  FirebaseFirestore+Rx.swift
//  abseil
//
//  Created by 정진규 on 2020/06/20.
//

import RxSwift
import RxCocoa

extension FirebaseFirestore: ReactiveCompatible {}

extension Reactive where Base: FirebaseFirestore {
    
    public func insert<T: Encodable>(key: String, object: T, withID: Bool = false) -> Single<Result<DocumentKey, FirestoreError>> {
        let single = Single<Result<DocumentKey, FirestoreError>>.create { [weak base] single in
            base?.insert(key: key, object: object, withID: withID, completion: { (result) in
                return single(.success(result))
            })
            return Disposables.create {}
        }
        return single
    }

    public func update(key: String, id: String, object: Encodable) -> Single<Result<Void, FirestoreError>> {
        let single = Single<Result<Void, FirestoreError>>.create { [weak base] single in
            base?.update(key: key, id: id, object: object, completion: { (result) in
                return single(.success(result))
            })
            return Disposables.create {}
        }
        return single
    }
    
    public func upsertDocumentField(key: String, id: String, data: [String: Any]) -> Single<Result<Void, FirestoreError>> {
        let single = Single<Result<Void, FirestoreError>>.create { [weak base] single in
            base?.upsertDocumentField(key: key, id: id, data: data, completion: { (result) in
                return single(.success(result))
            })
            return Disposables.create {}
        }
        return single
    }

    public func delete(key: String, id: String) -> Single<Result<Void, FirestoreError>> {
       let single = Single<Result<Void, FirestoreError>>.create { [weak base] single in
        base?.delete(key: key, id: id, completion: { (result) in
            return single(.success(result))
        })
           return Disposables.create {}
       }
       return single
   }
    
    public func read<T: Decodable>(key: String, id: String, type: T.Type) -> Single<Result<T, FirestoreError>> {
        let single = Single<Result<T, FirestoreError>>.create { [weak base] single in
            base?.read(key: key, id: id, type: type, completion: { (result) in
                return single(.success(result))
            })
            return Disposables.create {}
        }
        return single
    }
    
    public func list<T: Decodable>(key: String, orderBy: [QueryOrder], limit: Int, latestKey: String?, type: T.Type) -> Single<Result<[T], FirestoreError>> {
        let single = Single<Result<[T], FirestoreError>>.create { [weak base] single in
            base?.list(key: key, orderBy: orderBy, limit: limit, latestKey: latestKey, type: type, completion: { (result) in
                return single(.success(result))
            })
            return Disposables.create {}
        }
        return single
    }
}
