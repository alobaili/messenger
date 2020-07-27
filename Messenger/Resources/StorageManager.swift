//
//  StorageManager.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 26/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    public enum StorageError: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
    
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    
    private init() {}
    
    /// Uploads an image to firebase and completes with the URL of that image.
    /// - Parameters:
    ///   - data: The profile image data.
    ///   - fileName: The file name that will store the image data.
    ///   - completion: The completion takes a `Result` that succeeds with a `String` representing the URL of the uploaded image and fails with an `Error`, and returns `Void`.
    public func uploadProfileImage(with data: Data, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        storage.child("images/\(fileName)").putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Failed to upload: \(error)")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.getDownloadURL(for: "images/\(fileName)") { (result) in
                switch result {
                    case .success(let url): completion(.success(url))
                    case .failure(let error): completion(.failure(error))
                }
            }
        }
    }
    
    public func getDownloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        storage.child(path).downloadURL { (url, error) in
            if let error = error {
                print("Failed to get download URL: \(error)")
                completion(.failure(StorageError.failedToGetDownloadURL))
                return
            }
            
            print("Download URL returned: \(url!)")
            completion(.success(url!))
        }
    }
    
    
}
