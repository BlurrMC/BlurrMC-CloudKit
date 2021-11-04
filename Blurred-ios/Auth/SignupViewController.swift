//
//  SignupViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/26/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import TTGSnackbar
import CloudKit

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    
    // MARK: Outlets
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var SignUpButton: UIButton!
    
    
    // MARK: Back Button Tapped
    @IBAction func BackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Send the new user's information
    func sendSignupCreds() {
        // Quick Validatons
        if (nameTextField.text?.isEmpty)! ||
            (usernameTextField.text?.isEmpty)! ||
            (emailTextField.text?.isEmpty)! ||
            (passwordTextField.text?.isEmpty)! ||
            (confirmPasswordTextField.text?.isEmpty)! {
            popupMessages().showMessage(title: "Alert", message: "A field is empty. Please fill in all fields.", alertActionTitle: "OK", viewController: self)
            return
        }
        if ((passwordTextField.text?.elementsEqual(confirmPasswordTextField.text!))! != true) {
            popupMessages().showMessage(title: "Alert", message: "Confirmation passwords do not match. Try again.", alertActionTitle: "OK", viewController: self)
            return // YA YA YA Y A YA
        }
        if passwordTextField.text!.count < 6 {
            popupMessages().showMessage(title: "Alert", message: "Your password must be at least six characters long.", alertActionTitle: "OK", viewController: self)
            return
        }
        
        // Loading Animation
        let myActivityIndicator = DifferencesActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        
        // Set record
        let record = CKRecord(recordType: "Users")
        record.setValuesForKeys([
            "name": self.nameTextField.text!,
            "email": self.emailTextField.text!,
            "password": self.passwordTextField.text!,
            "username": self.usernameTextField.text!
        ])
        
        // Validate data and upload it
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        let query = CKQuery(recordType: "Users", predicate: NSPredicate(format: "TRUEPREDICATE", argumentArray: nil))
        database.perform(query, inZoneWith: CKRecordZone.default().zoneID) { [weak self] records, error in
            guard let self = self else { return }
            
            if error == nil {
                var userCanSignup: Bool = true
                
                for record in records! {
                    if record.object(forKey: "username") as? String == self.usernameTextField.text {
                        userCanSignup = false
                    }
                }
                
                if userCanSignup != true {
                    // User can't signup
                    popupMessages().showMessage(title: "Error", message: "Cannot signup. Username is already taken. Come on man!", alertActionTitle: "OK", viewController: self)
                    DispatchQueue.main.async {
                        self.SignUpButton.isEnabled = true
                    }
                    print("error code: asdfuhasdufha0sdfh")
                    self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                } else {
                    // User can signup
                    database.save(record, completionHandler: { _, error in
                        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
                        
                        // Signup error check
                        if let error = error {
                            let snackbar = TTGSnackbar(message: "Error signing up. Keep trying!", duration: .middle)
                            DispatchQueue.main.async {
                                snackbar.show()
                                self.SignUpButton.isEnabled = true
                            }
                            print("error code: adsuaifaudfh82, error: \(error)")
                            return
                        }
                        
                        // Signup Succeeded
                        popupMessages().showMessage(title: "Success", message: "You have succesfully signed up.", alertActionTitle: "OK", viewController: self)
                        DispatchQueue.main.async {
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
                }
                
            }
            
        }
    }
    
    
    // MARK: Remove Activity Indicator
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    
    
    // MARK: Sign Up Button Tapped
    @IBAction func signUpButtonTapped(_ sender: Any) {
        self.SignUpButton.isEnabled = false
        sendSignupCreds()
    }
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.SignUpButton.isEnabled = true
    }
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // You gotta hide it (the drugs (ex. concaine))
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.title = "Sign Up"
        confirmPasswordTextField?.delegate = self
        passwordTextField?.delegate = self
        emailTextField?.delegate = self
        usernameTextField?.delegate = self
        nameTextField?.delegate = self
        nameTextField?.tag = 0
        usernameTextField?.tag = 1
        emailTextField?.tag = 2
        passwordTextField?.tag = 3
        confirmPasswordTextField?.tag = 4
        self.nameTextField.textContentType = .name
        self.usernameTextField.textContentType = .username
        self.emailTextField.textContentType = .emailAddress
        self.passwordTextField.textContentType = .newPassword
        self.passwordTextField.textContentType = .password
    }
    
    
    // MARK: Text Field Should Return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            textField.resignFirstResponder()
            usernameTextField.becomeFirstResponder()
        } else if textField == usernameTextField {
            textField.resignFirstResponder()
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            textField.resignFirstResponder()
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            confirmPasswordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    

}
