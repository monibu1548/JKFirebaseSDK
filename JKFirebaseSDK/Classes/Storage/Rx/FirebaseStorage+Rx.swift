//
//  FirebaseStorage+Rx.swift
//  JKFirebaseSDK
//
//  Created by 정진규 on 2020/06/25.
//

import Foundation
import RxSwift
import RxCocoa

extension FirebaseStorage: ReactiveCompatible {}

extension Reactive where Base: FirebaseStorage {
    public func insertImage(path: String, image: UIImage) -> Single<Result<URL, FirebaseStorageError>> {
        let single = Single<Result<URL, FirebaseStorageError>>.create { [weak base] single in
            base?.insertImage(path: path, image: image) { (result) in
                return single(.success(result))
            }
            return Disposables.create {}
        }
        return single
    }

    public func deleteImage(downloadURL: String) -> Single<Result<Void, FirebaseStorageError>> {
        let single = Single<Result<Void, FirebaseStorageError>>.create { [weak base] single in
            base?.deleteImage(downloadURL: downloadURL, completion: { (result) in
                return single(.success(result))
            })
            return Disposables.create {}
        }
        return single
    }
}
