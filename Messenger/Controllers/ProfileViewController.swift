//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 21/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import FirebaseAuth
import AuthenticationServices

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    enum Option: String, CaseIterable {
        case signOut = "Sign Out"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appleIDCredentialRevoked),
                                               name: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
                                               object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: ASAuthorizationAppleIDProvider.credentialRevokedNotification, object: nil)
    }
    
    func showLoginScreen() {
        let loginViewController = SignInViewController()
        let navigationController = UINavigationController(rootViewController: loginViewController)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        present(navigationController, animated: true)
    }
    
    @objc func appleIDCredentialRevoked() {
        if let providerID = Auth.auth().currentUser?.providerData.first?.providerID,
            providerID == "apple.com" {
            signOut()
        }
    }
    
    fileprivate func signOut() {
        do {
            // Remove the user's Sign In with Apple ID
            if let providerID = Auth.auth().currentUser?.providerData.first?.providerID,
                providerID == "apple.com" {
                UserDefaults.standard.set(nil, forKey: UserDefaults.MessengerKeys.kAppleAuthorizedUserID)
            }
            try Auth.auth().signOut()
            showLoginScreen()
        } catch {
            print("Failed to sign out: \(error)")
        }
    }
    

}

extension ProfileViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Option.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = Option.allCases[indexPath.row].rawValue
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .systemRed
        return cell
    }
    
    
}

extension ProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let option = Option.allCases[indexPath.row]
        
        switch option {
            case .signOut: signOut()
        }
    }
    
    
}
