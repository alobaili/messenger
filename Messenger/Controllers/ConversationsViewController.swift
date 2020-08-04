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
        
        fetchConversations()
        
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
        
        viewController.completion = { [unowned self] (selectedUserData) in
            self.createNewConversation(forUser: selectedUserData)
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
        let viewController = ChatViewController(userID: user.id, conversationID: nil)
        viewController.isNewConversation = true
        viewController.title = "\(firstName) \(lastName)"
        viewController.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(viewController, animated: true)
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
    
    private func fetchConversations() {
        tableView.isHidden = false
    }
    
    private func startListeningForConversations() {
        guard let userID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) else { return }
        
        if let observer = signInObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        DatabaseManager.shared.getAllConversations(forUserID: userID.safeForDatabaseReferenceChild()) { [unowned self] (result) in
            switch result {
                case .success(let conversations):
                    guard !conversations.isEmpty else { return }
                
                    self.conversations = conversations
                
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Failed to get conversations: \(error)")
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
        
        let viewController = ChatViewController(userID: conversation.otherUserID, conversationID: conversation.id)
        viewController.title = conversation.name
        viewController.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    
}
