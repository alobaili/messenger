//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 21/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    
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
        imageView.image = UIImage(systemName: "person.fill")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemGray.cgColor
        return imageView
    }()
    
    private let firstNameTextField: UITextField = {
        let textField = UITextField()
        textField.returnKeyType = .continue
        textField.borderStyle = .roundedRect
        textField.placeholder = "First name..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textContentType = .name
        return textField
    }()
    
    private let lastNameTextField: UITextField = {
        let textField = UITextField()
        textField.returnKeyType = .continue
        textField.borderStyle = .roundedRect
        textField.placeholder = "Last name..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textContentType = .familyName
        return textField
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
        textField.textContentType = .newPassword
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Register", for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Create Account"
        view.backgroundColor = .systemBackground
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfileImage)))
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(firstNameTextField)
        contentView.addSubview(lastNameTextField)
        contentView.addSubview(emailTextField)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(registerButton)
        
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
            
            firstNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            firstNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            firstNameTextField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            
            lastNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            lastNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            lastNameTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 20),
            
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            emailTextField.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 20),
            
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            
            registerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            registerButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            registerButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            registerButton.heightAnchor.constraint(equalToConstant: 44),
            registerButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageView.layer.cornerRadius = imageView.frame.height / 2
    }
    
    @objc private func registerButtonTapped() {
        guard
            let firstName = firstNameTextField.text,
            let lastName = lastNameTextField.text,
            let email = emailTextField.text,
            let password = passwordTextField.text,
            !firstName.isEmpty,
            !lastName.isEmpty,
            !email.isEmpty,
            !password.isEmpty,
            password.count >= 6
            else {
                alertUserRegisterError(message: "Please enter all information to create a new account.")
                return
        }
        
        DatabaseManager.shared.userExists(withEmail: email) { [unowned self] (exist) in
            guard !exist else {
                self.alertUserRegisterError(message: "A user already exists with email\n\(email)")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                if let error = error {
                    print("Error creating user: \(error)")
                    return
                }
                
                DatabaseManager.shared.insertUser(MessengerUser(firstName: firstName,
                                                                lastName: lastName,
                                                                emailAddress: email))
                self.navigationController?.dismiss(animated: true)
            }
        }
    }
    
    func alertUserRegisterError(message: String) {
        let alertController = UIAlertController(title: "Woops",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    @objc func didTapChangeProfileImage() {
        presentPhotoActionSheet()
    }
    
    
}

// MARK: - Text Field Delegate

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
            case firstNameTextField: lastNameTextField.becomeFirstResponder()
            case lastNameTextField: emailTextField.becomeFirstResponder()
            case emailTextField: passwordTextField.becomeFirstResponder()
            case passwordTextField:
                textField.resignFirstResponder()
                registerButtonTapped()
            default: textField.resignFirstResponder()
        }
        
        return true
    }
    
    
}

// MARK: - Image Picker Controller Delegate

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Add a Profile Picture Using",
                                            message: nil,
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil))
        actionSheet.addAction(UIAlertAction(
            title: "Camera",
            style: .default,
            handler: { [unowned self] (_) in
                self.presentImagePicker(sourceType: .camera)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Photo Library",
            style: .default,
            handler: { [unowned self] (_) in
                self.presentImagePicker(sourceType: .photoLibrary)
        }))
        present(actionSheet, animated: true)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        imageView.image = info[.editedImage] as? UIImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    
}
