//
//  SignInViewController.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 21/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import CryptoKit
import FirebaseAuth
import AuthenticationServices
import JGProgressHUD

class SignInViewController: UIViewController {
    
    private let progressHUD = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "text.bubble")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.borderStyle = .roundedRect
        textField.placeholder = "Email address..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textContentType = .username
        textField.keyboardType = .emailAddress
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        textField.placeholder = "Password..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textContentType = .password
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign In", for: .normal)
        button.tintColor = .white
        button.backgroundColor = .link
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return button
    }()
    
    private var signInWithAppleButton: ASAuthorizationAppleIDButton!
    
    private var signInObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Sign In"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        loginButton.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(emailTextField)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(loginButton)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 1),
            
            imageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1/3),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1),
            imageView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            emailTextField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            loginButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        recreateSignInWithAppleButton(for: traitCollection.userInterfaceStyle)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        recreateSignInWithAppleButton(for: traitCollection.userInterfaceStyle)
    }
    
    func recreateSignInWithAppleButton(for style: UIUserInterfaceStyle) {
        switch style {
            case .light:
                signInWithAppleButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
            default:
                signInWithAppleButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .white)
        }
        signInWithAppleButton.translatesAutoresizingMaskIntoConstraints = false
        signInWithAppleButton.cornerRadius = 12
        
        contentView.addSubview(signInWithAppleButton)
        
        NSLayoutConstraint.activate([
            signInWithAppleButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            signInWithAppleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            signInWithAppleButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            signInWithAppleButton.heightAnchor.constraint(equalToConstant: 44),
            signInWithAppleButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
        
        signInWithAppleButton.addTarget(self, action: #selector(signInWithAppleButtonTapped), for: .touchUpInside)
    }
    
    @objc private func signInButtonTapped() {
        view.endEditing(false)
        
        guard let email = emailTextField.text,
            let password = passwordTextField.text,
            !email.isEmpty,
            !password.isEmpty,
            password.count >= 6
            else {
                alertUserLoginError()
                return
        }
        
        progressHUD.show(in: view)
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.progressHUD.dismiss()
            }
            
            if let error = error {
                print("Error creating user: \(error)")
                return
            }
            
            let user = result!.user
            print("Sign in successful for user: \(user)")
            
            UserDefaults.standard.set(email, forKey: UserDefaults.MessengerKeys.kUserID)
            
            NotificationCenter.default.post(name: .didSignIn, object: nil)
            
            self.navigationController?.dismiss(animated: true)
        }
    }
    
    fileprivate var currentNonce: String?
    
    @objc private func signInWithAppleButtonTapped() {
        let nonce = String.randomNonceString()
        currentNonce = nonce
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = String.sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        authorizationController.presentationContextProvider = self
        authorizationController.delegate = self
        
        authorizationController.performRequests()
    }
    
    func alertUserLoginError() {
        let alertController = UIAlertController(title: "Woops",
                                                message: "Please enter all information to sign in.",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    @objc private func didTapRegister() {
        let registerViewController = RegisterViewController()
        navigationController?.pushViewController(registerViewController, animated: true)
    }
    

}

// MARK: - Text Field Delegate
extension SignInViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            signInButtonTapped()
        }
        
        return true
    }
    
    
}

// MARK: - Sign In with Apple

extension SignInViewController: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window!
    }
    
    
}

extension SignInViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard let error = error as? ASAuthorizationError else { return }
        
        switch error.code {
            case .unknown:
            break
            case .canceled:
            break
            case .invalidResponse:
            break
            case .notHandled:
            break
            case .failed:
            break
            @unknown default:
            break
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Save the authorized user ID for future reference
            UserDefaults.standard.set(appleIDCredential.user, forKey: UserDefaults.MessengerKeys.kUserID)
            
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            progressHUD.show(in: view)
            
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.progressHUD.dismiss()
                }
                
                if let error = error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error.localizedDescription)
                    return
                }
                
                // User is signed in to Firebase with Apple.
                DatabaseManager.shared.userExists(withID: appleIDCredential.user) { (exists) in
                    if !exists {
                        let user = MessengerUser(id: appleIDCredential.user,
                                                 firstName: appleIDCredential.fullName?.givenName,
                                                 lastName: appleIDCredential.fullName?.familyName,
                                                 conversations: nil)
                        DatabaseManager.shared.insertUser(user) { success in
                            if success {
                                if let firstName = appleIDCredential.fullName?.givenName, let lastName = appleIDCredential.fullName?.familyName {
                                    let changeRequest = authResult?.user.createProfileChangeRequest()
                                    changeRequest?.displayName = "\(firstName) \(lastName)"
                                    changeRequest?.commitChanges() { (error) in
                                        if let error = error {
                                            print("Error committing profile change request: \(error)")
                                        } else {
                                            guard let image = UIImage(systemName: "person.fill"), let data = image.pngData() else {
                                                return
                                            }
                                            
                                            let fileName = user.profileImageFileName
                                            
                                            StorageManager.shared.uploadProfileImage(with: data, fileName: fileName) { (result) in
                                                switch result {
                                                    case .success(let url):
                                                        print(url)
                                                        UserDefaults.standard.set(url, forKey: UserDefaults.MessengerKeys.kProfileImageURL)
                                                        
                                                        NotificationCenter.default.post(name: .didSignIn, object: nil)
                                                        
                                                        self.navigationController?.dismiss(animated: true)
                                                    case .failure(let error):
                                                        print(error)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        
                    } else {
                        NotificationCenter.default.post(name: .didSignIn, object: nil)
                        
                        self.navigationController?.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    
}
