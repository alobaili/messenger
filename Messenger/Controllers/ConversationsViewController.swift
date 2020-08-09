//
//  ConversationsViewController.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 21/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsViewController: UIViewController {
    
    private let progressHUD = JGProgressHUD(style: .dark)
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true
        tableView.separatorInset.left = 100
        tableView.rowHeight = 75 + 12
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.reuseID)
        return tableView
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No Conversations"
        label.textAlignment = .center
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private var conversations = [Conversation]()
    
    private var signInObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        
        setupAutoLayout()
        
        startListeningForConversations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        signInObserver = NotificationCenter.default.addObserver(forName: .didSignIn, object: nil, queue: .main, using: { [weak self] (_) in
            guard let self = self else { return }
            
            self.startListeningForConversations()
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuthentication()
    }
    
    @objc private func didTapComposeButton() {
        let viewController = NewConversationViewController()
        
        viewController.completion = { [weak self] (selectedUserData) in
            guard let self = self else { return }
            
            if let targetConversation = self.conversations.first(where: { $0.otherUserID == selectedUserData.id.safeForDatabaseReferenceChild() }) {
                self.openConversation(targetConversation, isNewConversation: false)
            } else {
                self.createNewConversation(forUser: selectedUserData)
            }
            
        }
        
        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, animated: true)
    }
    
    private func createNewConversation(forUser user: MessengerUser) {
        guard
            let firstName = user.firstName,
            let lastName = user.lastName
            else {
            return
        }
        
        // Check in the database if a conversation already exists for these two users
        // If true, reuse its ID
        // If false, create a new conversation in the database between these two users
        
        DatabaseManager.shared.getConversation(withRecipientID: user.id) { [weak self] (conversationID) in
            guard let self = self else { return }
            
            if let conversationID = conversationID {
                let viewController = ChatViewController(userID: user.id.safeForDatabaseReferenceChild(), conversationID: conversationID)
                viewController.isNewConversation = false
                viewController.title = "\(firstName) \(lastName)"
                viewController.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(viewController, animated: true)
            } else {
                let viewController = ChatViewController(userID: user.id.safeForDatabaseReferenceChild(), conversationID: nil)
                viewController.isNewConversation = true
                viewController.title = "\(firstName) \(lastName)"
                viewController.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
    
    private func setupAutoLayout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            noConversationsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            noConversationsLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            noConversationsLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            noConversationsLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func validateAuthentication() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginViewController = SignInViewController()
            let navigationController = UINavigationController(rootViewController: loginViewController)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.modalTransitionStyle = .crossDissolve
            present(navigationController, animated: false)
        }
    }
    
    private func startListeningForConversations() {
        guard let userID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) else { return }
        
        if let observer = signInObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        DatabaseManager.shared.getAllConversations(forUserID: userID.safeForDatabaseReferenceChild()) { [weak self] (conversations) in
            guard let self = self else { return }
            
            self.conversations = conversations
            
            DispatchQueue.main.async {
                self.tableView.isHidden = self.conversations.isEmpty
                self.noConversationsLabel.isHidden = !self.conversations.isEmpty
                self.tableView.reloadData()
            }
        }
    }


}

// MARK: - Table View Data Source
extension ConversationsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.reuseID, for: indexPath) as! ConversationTableViewCell
        
        
        
        cell.configure(with: conversations[indexPath.row])
        
        return cell
    }
    
    
}


// MARK: - Table View Delegate
extension ConversationsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        
        openConversation(conversation, isNewConversation: false)
    }
    
    func openConversation(_ conversation: Conversation, isNewConversation: Bool) {
        let viewController = ChatViewController(userID: conversation.otherUserID,
                                                conversationID: isNewConversation ? nil : conversation.id)
        viewController.isNewConversation = isNewConversation
        viewController.title = conversation.name
        viewController.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            DatabaseManager.shared.deleteConversation(conversations[indexPath.row])
        }
    }
    
    
}
