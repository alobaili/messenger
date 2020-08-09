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
import SDWebImage

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    enum Option: String, CaseIterable {
        case signOut = "Sign Out"
    }
    
    private var signInObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backgroundColor = .systemGroupedBackground
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance?.shadowColor = nil
        navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableHeaderView = createTableHeaderView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = Auth.auth().currentUser?.displayName
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appleIDCredentialRevoked),
                                               name: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
                                               object: nil)
        
        signInObserver = NotificationCenter.default.addObserver(forName: .didSignIn, object: nil, queue: .main) { [weak self] (_) in
            guard let self = self else { return }
            
            self.tableView.tableHeaderView = self.createTableHeaderView()
        }
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
            UserDefaults.standard.set(nil, forKey: UserDefaults.MessengerKeys.kUserID)
            UserDefaults.standard.set(nil, forKey: UserDefaults.MessengerKeys.kProfileImageURL)
            try Auth.auth().signOut()
            showLoginScreen()
        } catch {
            print("Failed to sign out: \(error)")
        }
    }
    
    func createTableHeaderView() -> UIView? {
        guard let id = UserDefaults.standard.value(forKey: UserDefaults.MessengerKeys.kUserID) as? String else {
            return nil
        }
        
        if let observer = signInObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        let safeID = id.safeForDatabaseReferenceChild()
        let fileName = "\(safeID)_profile_image.png"
        let path = "images/\(fileName)"
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 200))
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .secondarySystemBackground
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.systemGray.cgColor
        imageView.layer.borderWidth = 2
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 75

        headerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 150),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        StorageManager.shared.getDownloadURL(for: path) { (result) in
            switch result {
                case .success(let url):
                    imageView.sd_setImage(with: url)
                case .failure(let error):
                    print("Failed to get download URL: \(error)")
            }
        }

        return headerView
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
