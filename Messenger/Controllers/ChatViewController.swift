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

struct Message: MessageType {
    
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    
}

extension MessageKind: CustomStringConvertible {
    
    public var description: String {
        switch self {
            case .text: return "text"
            case .attributedText: return "attributed_text"
            case .photo: return "photo"
            case .video: return "video"
            case .location: return "location"
            case .emoji: return "emoji"
            case .audio: return "audio"
            case .contact: return "contact"
            case .custom: return "custom"
        }
    }
    
    
}

struct Sender: SenderType {
    
    var senderId: String
    var displayName: String
    var photoURL: String
    
    
}

struct Media: MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    
}

class ChatViewController: MessagesViewController {
    
    public var isNewConversation = false
    public let otherUserID: String
    private let conversationID: String?
    
    private var messages = [Message]()
    private var currentUser = Sender(senderId: UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID)!,
                                     displayName: "Abdulaziz",
                                     photoURL: "")
    

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
            picker.delegate = self
            self.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] (_) in
            guard let self = self else { return }
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { (_) in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { (_) in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
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
    
    
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
            case .photo(let media):
                guard let imageURL = media.url else { return }
                let viewController = PhotoViewerViewController(with: imageURL)
                viewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(viewController, animated: true)
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
                .createNewConversation(withUserID: otherUserID, name: Auth.auth().currentUser?.displayName ?? "User", firstMessage: message) { [unowned self] (success) in
                    if success {
                        print("message sent")
                        self.isNewConversation = false
                        inputBar.inputTextView.text = nil
                    } else {
                        print("failed to send message")
                    }
            }
        } else {
            guard let conversationID = conversationID, let name = Auth.auth().currentUser?.displayName else { return }
            // Append to the existing conversation
            DatabaseManager.shared.sendMessage(message, recipientID: otherUserID, conversationID: conversationID, senderName: name) { (success) in
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
        
        guard let image = info[.originalImage] as? UIImage,
            let imageData = image.pngData(),
            let conversationID = conversationID,
            let senderName = Auth.auth().currentUser?.displayName
            else { return }
        
        // use this id for the message and the name of the image
        let id = createUniqueID()
        
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
                    
                    DatabaseManager.shared.sendMessage(message, recipientID: self.otherUserID, conversationID: conversationID, senderName: senderName) { (success) in
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
        
        // Send the message
    }
    
    
}
