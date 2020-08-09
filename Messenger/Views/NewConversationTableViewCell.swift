//
//  NewConversationTableViewCell.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 04/08/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import SDWebImage

class NewConversationTableViewCell: UITableViewCell {
    
    static let reuseID = "NewConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 75 / 2
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
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .disclosureIndicator
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        NSLayoutConstraint.activate([
            userImageView.heightAnchor.constraint(equalToConstant: 75),
            userImageView.widthAnchor.constraint(equalToConstant: 75),
            userImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            userImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            
            usernameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 10),
            usernameLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            usernameLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }
    
    func configure(with user: MessengerUser) {
        usernameLabel.text = "\(user.firstName ?? "") \(user.lastName ?? "")"
        
        let path = "images/\(user.id.safeForDatabaseReferenceChild())_profile_image.png"
        
        StorageManager.shared.getDownloadURL(for: path) { [weak self] (result) in
            guard let self = self else { return }
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
