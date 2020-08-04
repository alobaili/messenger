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
        uploadImage(with: data, path: "images/\(fileName)", fileName: fileName, completion: completion)
    }
    
    public func uploadMessageImage(with data: Data, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        uploadImage(with: data, path: "message_images/\(fileName)", fileName: fileName, completion: completion)
    }
    
    public func uploadMessageVideo(with fileURL: URL, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        storage.child("message_videos/\(fileName)").putFile(from: fileURL, metadata: nil) { [weak self] (metadata, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to upload: \(error)")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.getDownloadURL(for: "message_videos/\(fileName)") { (result) in
                switch result {
                    case .success(let url): completion(.success(url))
                    case .failure(let error): completion(.failure(error))
                }
            }
        }
    }
    
    private func uploadImage(with data: Data, path: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        storage.child(path).putData(data, metadata: nil) { [weak self] (metadata, error) in
            guard let self = self else { return }
            if let error = error {
                print("Failed to upload: \(error)")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.getDownloadURL(for: path) { (result) in
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
