//
//  SettingsViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/24/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet

class SettingsViewController: UIViewController {

    @IBAction func signOutButtonPressed(_ sender: Any) {
        let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
        let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
        myValet.removeObject(forKey: "Id")
        tokenValet.removeObject(forKey: "Token")
        myValet.removeAllObjects()
        tokenValet.removeAllObjects()
        if #available(iOS 13.0, *) {
            let signInPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
            let appDelegate = UIApplication.shared.delegate
            appDelegate?.window??.rootViewController = signInPage
        } else {
            let homePage = AuthenticateViewController()
            self.present(homePage, animated:true, completion:nil)
        }
        
    }
      
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true // Again with the tab barss.

        // Do any additional setup after loading the view.
        // I did not hit her!
    }
    @IBAction func settingsBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
