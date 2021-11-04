//
//  AuthenticateViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/24/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import TTGSnackbar
import CloudKit

class AuthenticateViewController: UIViewController, UITextFieldDelegate {
    
    
    // MARK: Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField?.delegate = self
        passwordTextField?.delegate = self
        usernameTextField?.tag = 0
        passwordTextField?.tag = 1
        self.passwordTextField.textContentType = .password
        self.usernameTextField.textContentType = .username
    }
    
    
    // MARK: Text Field Should Return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            textField.resignFirstResponder()
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: Submit Creds Button Tapped
    @IBAction func SubmitCreds(_ sender: UIButton) {
        sender.isEnabled = false
        sendCreds()
    }
    
    
    // MARK: Send credentials to login
    func sendCreds() {
        guard let username = usernameTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        let myActivityIndicator = DifferencesActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        let query = CKQuery(recordType: "Users", predicate: NSPredicate(format: "TRUEPREDICATE", argumentArray: nil))
        database.perform(query, inZoneWith: CKRecordZone.default().zoneID) { [weak self] records, error in
            guard let self = self else { return }
            
            self.removeActivityIndicator(activityIndicator: myActivityIndicator)
            if error == nil {
                
                
                for record in records! {
                    if record.object(forKey: "username") as? String == username || record.object(forKey: "email") as? String == password {
                        guard let passwordNum = Int(password) else { return }
                        if record.object(forKey: "password") as? Int == passwordNum {
                            // Login success
                            try? self.myValet.setString(username, forKey: "Id")
                            
                            DispatchQueue.main.async {
                                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                                guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainTabBarViewController") as? UITabBarController else { return }
                                self.present(nextViewController, animated: true, completion: nil)
                            }
                        } else {
                            // Wrong password
                            let snackbar = TTGSnackbar(message: "Password is incorrect. Please try again!", duration: .middle)
                            DispatchQueue.main.async {
                                snackbar.show()
                                self.loginButton.isEnabled = true
                            }
                        }
                    } else {
                        // Wrong email/username
                        let snackbar = TTGSnackbar(message: "Email or username is incorrect. Please try again!", duration: .middle)
                        DispatchQueue.main.async {
                            snackbar.show()
                            self.loginButton.isEnabled = true
                        }
                    }
                }
                
                
                
            } else {
                // Login failed for some reason
                let snackbar = TTGSnackbar(message: "Error signing in. Try again later!", duration: .middle)
                DispatchQueue.main.async {
                    snackbar.show()
                    self.loginButton.isEnabled = true
                }
            }
        }
    }
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        self.loginButton.isEnabled = true
    }
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    // MARK: Remove Activity Indicator
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }

}
