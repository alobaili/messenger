//
//  ChatViewController.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 25/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseAuth
import SDWebImage
import CoreServices
import AVKit
import CoreLocation
import MapKit

class ChatViewController: MessagesViewController {
    
    public var isNewConversation = false
    public let otherUserID: String
    private var conversationID: String?
    
    private var messages = [Message]()
    private var currentUser = Sender(senderId: UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID)!,
                                     displayName: "Abdulaziz",
                                     photoURL: "")
    
    private var senderProfileImageURL: URL?
    private var recipientProfileImageURL: URL?
    

    init(userID: String, conversationID: String?) {
        otherUserID = userID
        self.conversationID = conversationID
        super.init(nibName: nil, bundle: nil)
        
        if let conversationID = self.conversationID {
            startListeningForMessages(forConversationID: conversationID)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        setupAttachButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func setupAttachButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            guard let self = self else { return }
            
            self.presentAddAttachmentActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        messageInputBar.leftStackView.alignment = .fill
        messageInputBar.rightStackView.alignment = .fill
    }
    
    private func presentAddAttachmentActionSheet() {
        let actionSheet = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            self.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            self.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }
            
            self.presentLocationPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { (_) in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let locationPicker = LocationPickerViewController()
        
        locationPicker.completion = { [weak self] (selectedCoordinate) in
            guard let self = self, let conversationID = self.conversationID else { return }
            
            let latitude = selectedCoordinate.latitude
            let longitude = selectedCoordinate.longitude
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                    size: .zero)
            
            let messageID = "message_location_\(self.createUniqueID())"
            
            let message = Message(sender: self.currentUser,
                                  messageId: messageID,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            // Send the message
            DatabaseManager.shared.sendMessage(message, recipientID: self.otherUserID, conversationID: conversationID, name: self.title ?? "") { (success) in
                if success {
                    print("Sent location message")
                } else {
                    print("Failed to send location message")
                }
            }
        }
        
        let navigationController = UINavigationController(rootViewController: locationPicker)
        present(navigationController, animated: true)
    }
    
    private func startListeningForMessages(forConversationID conversationID: String) {
        DatabaseManager.shared.getAllMessages(forConversationID: conversationID) { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
                case .success(let messages):
                    guard !messages.isEmpty else { return }
                
                    self.messages = messages
                
                    DispatchQueue.main.async {
                        self.messagesCollectionView.reloadDataAndKeepOffset()
                    }
                case .failure(let error):
                    print("Failed to get messages: \(error)")
            }
        }
    }
    

}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    
    
    func currentSender() -> SenderType {
        currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        
        switch message.kind {
            case .photo(let media):
                guard let imageURL = media.url else { return }
                imageView.sd_setImage(with: imageURL)
            default:
                break
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if message.sender.senderId == currentUser.senderId {
            // Show our image
            if let senderProfileImageURL = senderProfileImageURL {
                avatarView.sd_setImage(with: senderProfileImageURL)
            } else {
                guard let id = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) else { return }
                let path = "images/\(id.safeForDatabaseReferenceChild())_profile_image.png"
                StorageManager.shared.getDownloadURL(for: path) { [weak self] (result) in
                    guard let self = self else { return }
                    
                    switch result {
                        case .success(let url):
                            DispatchQueue.main.async {
                                self.senderProfileImageURL = url
                                avatarView.sd_setImage(with: url)
                            }
                        case .failure(let error):
                            print(error)
                    }
                }
            }
        } else {
            // Show recipient image
            if let recipientProfileImageURL = recipientProfileImageURL {
                avatarView.sd_setImage(with: recipientProfileImageURL)
            } else {
                let id = self.otherUserID
                let path = "images/\(id.safeForDatabaseReferenceChild())_profile_image.png"
                StorageManager.shared.getDownloadURL(for: path) { [weak self] (result) in
                    guard let self = self else { return }
                    
                    switch result {
                        case .success(let url):
                            DispatchQueue.main.async {
                                self.recipientProfileImageURL = url
                                avatarView.sd_setImage(with: url)
                        }
                        case .failure(let error):
                            print(error)
                    }
                }
            }
        }
    }
    
    
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        
        switch message.kind {
            case .location(let locationItem):
                let coordinate = locationItem.location.coordinate
                let viewController = LocationPickerViewController(coordinate: coordinate)
                let navigationController = UINavigationController(rootViewController: viewController)
                present(navigationController, animated: true)
            default:
                break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
            case .photo(let media):
                guard let imageURL = media.url else { return }
                let viewController = PhotoViewerViewController(with: imageURL)
                viewController.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(viewController, animated: true)
            case .video(let media):
                guard let videoURL = media.url else { return }
                let viewController = AVPlayerViewController()
                viewController.player = AVPlayer(url: videoURL)
                present(viewController, animated: true) {
                    viewController.player?.play()
                }
            default:
                break
        }
    }
    
    
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else { return }
        
        print("Sending: \(text)")
        
        let message = Message(sender: currentUser, messageId: createUniqueID(), sentDate: Date(), kind: .text(text))

        if isNewConversation {
            // Create a new conversation in the database
            DatabaseManager.shared
                .createNewConversation(withUserID: otherUserID, name: title ?? "User", firstMessage: message) { [weak self] (success) in
                    guard let self = self else { return }
                    
                    if success {
                        print("message sent")
                        self.isNewConversation = false
                        inputBar.inputTextView.text = nil
                        let newConversationID = "conversation_\(message.messageId)"
                        self.conversationID = newConversationID
                        self.startListeningForMessages(forConversationID: newConversationID)
                    } else {
                        print("failed to send message")
                    }
            }
        } else {
            guard let conversationID = conversationID, let name = title else { return }
            // Append to the existing conversation
            DatabaseManager.shared.sendMessage(message, recipientID: otherUserID, conversationID: conversationID, name: name) { (success) in
                if success {
                    print("message sent")
                    inputBar.inputTextView.text = nil
                } else {
                    print("failed to send message")
                }
            }
        }
    }
    
    private func createUniqueID() -> String {
        // date, otherUserID, currentUserID, UUID
        let id = "\(UUID().uuidString)_\(Date().timeIntervalSinceReferenceDate)"
            .replacingOccurrences(of: " ", with: "-")
            .safeForDatabaseReferenceChild()
        print("created message ID: \(id)")
        return id
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let conversationID = conversationID,
            let senderName = Auth.auth().currentUser?.displayName
            else { return }
        
        // use this id for the message and the name of the image
        let id = createUniqueID()
        
        if let image = info[.originalImage] as? UIImage, let imageData = image.pngData() {
            // Upload the image
            let fileName = "message_image_\(id).png"
            StorageManager.shared.uploadMessageImage(with: imageData, fileName: fileName) { [weak self] (result) in
                guard let self = self else { return }
                
                switch result {
                    case .success(let url):
                        print("Successfully uploaded image: \(url.absoluteString)")
                        
                        let placeholderImage = UIImage(systemName: "plus")!
                        
                        let image = Media(url: url, image: nil, placeholderImage: placeholderImage, size: .zero)
                        
                        let message = Message(sender: self.currentUser, messageId: id, sentDate: Date(), kind: .photo(image))
                        
                        // Send the message
                        DatabaseManager.shared.sendMessage(message, recipientID: self.otherUserID, conversationID: conversationID, name: senderName) { (success) in
                            if success {
                                print("Sent image message")
                            } else {
                                print("Failed to send image message")
                            }
                        }
                    case .failure(let error):
                        print("Failed to upload message image: \(error)")
                }
            }
        } else if let videoURL = info[.mediaURL] as? URL {
            // Upload the video
            let fileName = "message_video_\(id).mov"
            
            let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            // I had to copy the video from the sandboxed URL to a temporary directory
            // because of iOS 13 issuing this error: "Failed to issue sandbox extension for file"
            // See: https://stackoverflow.com/a/57973541/10654098
            do {
                try FileManager.default.copyItem(at: videoURL, to: temporaryDirectory)
            } catch {
                fatalError("Failed to move item to temporary directory: \(error)")
            }
            
            StorageManager.shared.uploadMessageVideo(with: temporaryDirectory, fileName: fileName) { [weak self] (result) in
                guard let self = self else { return }
                
                switch result {
                    case .success(let url):
                        print("Successfully uploaded video: \(url.absoluteString)")
                        
                        let placeholderImage = UIImage(systemName: "plus")!
                        
                        let image = Media(url: url, image: nil, placeholderImage: placeholderImage, size: .zero)
                        
                        let message = Message(sender: self.currentUser, messageId: id, sentDate: Date(), kind: .video(image))
                        
                        // Send the message
                        DatabaseManager.shared.sendMessage(message, recipientID: self.otherUserID, conversationID: conversationID, name: senderName) { (success) in
                            if success {
                                print("Sent image message")
                            } else {
                                print("Failed to send image message")
                            }
                    }
                    case .failure(let error):
                        print("Failed to upload message image: \(error)")
                }
            }
        }
    }
    
    
}
