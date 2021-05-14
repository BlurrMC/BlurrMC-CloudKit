//
//  OTPViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/11/21.
//  Copyright © 2021 BlurrMC. All rights reserved.
//

import UIKit
import Alamofire
import Valet

class OTPViewController: UIViewController {
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    // MARK: Variables
    var login = String()
    var password = String()
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "2FA"
        // Colors
        if traitCollection.userInterfaceStyle == .light || traitCollection.userInterfaceStyle == .unspecified {
            self.view.backgroundColor = UIColor(hexString: "#eaeaea")
        } else {
            self.view.backgroundColor = UIColor(hexString: "#2d2d2d")
        }
    }
    
    
    @IBOutlet weak var OTPCode: UITextField!
    @IBAction func loginButtonTap(_ sender: Any) {
        loginUser()
    }
    
    // MARK: Submit OTP and login credentials
    func loginUser() {
        guard let otpCodeText = self.OTPCode.text else {
            self.showMessage(title: "Error", message: "No 2FA Code Provided", alertActionTitle: "OK")
            return
        }
        let params = [
            "login": login,
            "password": password,
            "otp_attempt": otpCodeText
        ] as [String : Any]
        AF.request("http://10.0.0.2:3000/api/v1/sessions/", method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { (response) in
            guard let data = response.data else { return }
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let error = JSON?["error"] as? String {
                    self.showMessage(title: "Error", message: "Invalid 2FA Code", alertActionTitle: "OK")
                    print(error)
                    return
                }
                let accessToken = JSON?["token"] as? String
                let errorToken = JSON?["error"] as? String
                if ((errorToken?.isEmpty) == nil) {
                    print("No error")
                } else {
                    self.showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK")
                }
                if accessToken?.isEmpty == nil {
                    self.showMessage(title: "Incorrect Credentials", message: "You have typed in the wrong credentials. Try again.", alertActionTitle: "OK")
                } else {
                    guard let userIdInt = JSON?["id"] as? Int else { return }
                    let userId = String(userIdInt)
                    try? self.tokenValet.setString(accessToken!, forKey: "Token")
                    try? self.myValet.setString(userId, forKey: "Id")
                    DispatchQueue.main.async {
                        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "MainTabBarViewController") as? UITabBarController else { return }
                        self.present(nextViewController, animated: true, completion: nil)
                    }
                }
            } catch {
                print("error code: asiojzxcv9023rwes")
            }
        }
    }
    
    // MARK: Show Message
    func showMessage(title: String, message: String, alertActionTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: alertActionTitle, style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

}
