//
//  UploadDetailsViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/25/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Alamofire
import AVKit

class UploadDetailsViewController: UIViewController {
    
    var videoDetails: URL!
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func doneButton(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        uploadRequest()
    }
    @IBOutlet weak var thumbnailView: UIImageView!
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    @IBOutlet weak var descriptionField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    func viewWillAppear() {
        AVAsset(url: videoDetails).generateThumbnail { [weak self] (image) in
            DispatchQueue.main.async {
                guard let image = image else { return }
                self?.thumbnailView.image = image
            }
        }
    }
    
    func uploadRequest() { // Move this to upload details and pass data using segue.
        let myActivityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        let userId: String? = myValet.string(forKey: "Id")
        let token: String? = tokenValet.string(forKey: "Token")
        let Id = Int(userId!)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append("\(self.descriptionField.text ?? "")".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "video[description]")
                multipartFormData.append(self.videoDetails, withName: "video[clip]", fileName: "clip.mp4", mimeType: "video/mp4")
                multipartFormData.append("\(Id!)".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "user[Id]")

        },
            to: "http://10.0.0.2:3000/api/v1/videouploads.json", method: .post, headers: headers)
            .response { resp in
                print(resp)


        }
        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
    }
    // I want to die
    func showErrorContactingServer() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)z
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }

}
extension AVAsset {

    func generateThumbnail(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            let imageGenerator = AVAssetImageGenerator(asset: self)
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let times = [NSValue(time: time)]
            imageGenerator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { _, image, _, _, _ in
                if let image = image {
                    completion(UIImage(cgImage: image))
                } else {
                    completion(nil)
                }
            })
        }
    }
}
