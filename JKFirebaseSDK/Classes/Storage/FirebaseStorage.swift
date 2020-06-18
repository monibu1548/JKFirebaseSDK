//
//  FirebaseStorage.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/24.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import Foundation
import FirebaseStorage

enum FirebaseStorageError: Error {
    case convertDataError
    case uploadError
    case deleteError
    case defaultError
}

class FirebaseStorage {

    static let shared = FirebaseStorage()
    private let storage = Storage.storage().reference()

    private init() {}

    func putImage(path: String, image: UIImage, completion: @escaping (_ ref: Result<URL, FirebaseStorageError>)->()) {
        let pathRef = pathToRef(path).child(String(Date().timeIntervalSince1970)+".jpeg")
        
        guard let data = UIImageJPEGRepresentation(image, 0.2) else {
            pathRef.delete(completion: nil)
            completion(.failure(.convertDataError))
            return
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        pathRef.putData(data, metadata: metadata) { (_, error) in
            guard error == nil else {
                pathRef.delete(completion: nil)
                completion(.failure(.uploadError))
                return
            }

            pathRef.downloadURL { (downloadURL, error) in
                guard error == nil, let downloadURL = downloadURL else {
                    pathRef.delete(completion: nil)
                    completion(.failure(.uploadError))
                    return
                }
                completion(.success(downloadURL))
            }
        }
    }

    func delete(downloadURL: String, completion: @escaping (_ result: Result<Void, FirebaseStorageError>)->()) {
        reference(forURL: downloadURL).delete { (error) in
            guard error == nil else {
                completion(.failure(.deleteError))
                return
            }
            completion(.success(Void()))
        }
    }

    private func pathToRef(_ routesString : String) -> StorageReference {
        let routes = routesString.components(separatedBy: "/").filter { !$0.isEmpty }

        var ref = storage
        for route in routes {
            ref = ref.child(route)
        }

        return ref
    }

    func reference(forURL: String) -> StorageReference {
        return Storage.storage().reference(forURL: forURL)
    }
}
