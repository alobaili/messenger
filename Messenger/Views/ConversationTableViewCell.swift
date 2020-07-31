//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 31/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let reuseID = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .disclosureIndicator
        separatorInset.left = 120
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        NSLayoutConstraint.activate([
            userImageView.heightAnchor.constraint(equalToConstant: 100),
            userImageView.widthAnchor.constraint(equalToConstant: 100),
            userImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            userImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            
            usernameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 10),
            usernameLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            
            userMessageLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 10),
            userMessageLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 10),
            userMessageLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            userMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }
    
    func configure(with conversation: Conversation) {
        userMessageLabel.text = conversation.latestMessage.message
        usernameLabel.text = conversation.name
        
        let path = "images/\(conversation.otherUserID.safeForDatabaseReferenceChild())_profile_image.png"
        
        StorageManager.shared.getDownloadURL(for: path) { [unowned self] (result) in
            switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        self.userImageView.sd_setImage(with: url)
                    }
                case .failure(let error):
                    print("Failed to get download URL: \(error)")
            }
        }
    }
    
}
