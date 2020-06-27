//
//  FirebaseStorage.swift
//  iOS-Firebase
//
//  Created by JingyuJung on 2019/11/24.
//  Copyright © 2019 JingyuJung. All rights reserved.
//

import Foundation
import FirebaseStorage
import JKExtension

public enum FirebaseStorageError: Error {
    case convertDataError
    case uploadError
    case deleteError
    case defaultError
}

public class FirebaseStorage {

    public static let shared = FirebaseStorage()
    private var reference: StorageReference {
        #if DEBUG
        return Storage.storage().reference().child("environment").child("development")
        #else
        return Storage.storage().reference().child("environment").child("production")
        #endif
    }

    private init() {}

    public func insertImage(path: String, image: UIImage, completion: @escaping (_ ref: Result<URL, FirebaseStorageError>)->()) {
        let pathRef = pathToRef(path).child(String(Date().toTimestamp())+".jpeg")
        
        guard let data = image.jpegData(compressionQuality: 0.2) else {
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

    public func deleteImage(downloadURL: String, completion: @escaping (_ result: Result<Void, FirebaseStorageError>)->()) {
        urlToReference(forURL: downloadURL).delete { (error) in
            guard error == nil else {
                completion(.failure(.deleteError))
                return
            }
            completion(.success(Void()))
        }
    }

    private func pathToRef(_ routesString : String) -> StorageReference {
        let routes = routesString.components(separatedBy: "/").filter { !$0.isEmpty }

        var ref = reference
        for route in routes {
            ref = ref.child(route)
        }

        return ref
    }

    public func urlToReference(forURL: String) -> StorageReference {
        return Storage.storage().reference(forURL: forURL)
    }
}
