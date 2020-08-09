//
//  AppDelegate.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 21/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import AuthenticationServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        handleAppleIDCredentialRevokedWhileTerminated()
        
        return true
    }
    
    func handleAppleIDCredentialRevokedWhileTerminated() {
        if let userID = UserDefaults.standard.string(forKey: UserDefaults.MessengerKeys.kUserID) {
            // Check Apple ID credential state
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { [weak self] (credentialState, error) in
                guard let self = self else { return }
                
                switch credentialState {
                    case .authorized: break
                    case .notFound, .transferred, .revoked: self.signOut()
                    @unknown default:
                    fatalError("Unhandled unknown case")
                }
            }
        }
    }
    
    fileprivate func signOut() {
        do {
            // Remove the user's Sign In with Apple ID
            if let providerID = Auth.auth().currentUser?.providerData.first?.providerID,
                providerID == "apple.com" {
                UserDefaults.standard.set(nil, forKey: UserDefaults.MessengerKeys.kUserID)
                try Auth.auth().signOut()
            }
        } catch {
            print("Failed to sign out: \(error)")
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }


}

