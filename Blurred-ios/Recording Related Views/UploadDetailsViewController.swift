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
    
    // MARK: Variables
    var videoDetails: URL!
    
    
    // MARK: Outlets
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var descriptionField: UITextField!
    
    // MARK: Back Button Tapped
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Done Button Tap
    @IBAction func doneButton(_ sender: Any) {
        uploadRequest()
    }
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        AVAsset(url: videoDetails).generateThumbnail { [weak self] (image) in
            DispatchQueue.main.async {
                // guard let image = image else { return }
                // let actualimage = image.rotate(radians: .pi / 2)
                self?.thumbnailView.image = image
            }
        }
    }
    
    
    // MARK: Did Receive Memory Warning
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    
    // MARK: Upload the video
    func uploadRequest() { // Move this to upload details and pass data using segue.
        let myActivityIndicator = DifferencesActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        myActivityIndicator.center = view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.view.addSubview(myActivityIndicator)
        }
        guard let userId: String = try? myValet.string(forKey: "Id") else { return }
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append("\(self.descriptionField.text ?? "")".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "video[description]") // Shows as an unknown paramater
                multipartFormData.append(self.videoDetails, withName: "video[clip]", fileName: "clip.mp4", mimeType: "video/mp4")
                multipartFormData.append(userId.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "user[Id]")

        },
            to: "https://blurrmc.com/api/v1/videouploads", method: .post, headers: headers).responseJSON(completionHandler: { result in
                guard let data = result.data else { return }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
                    if let parseJSON = json {
                        NotificationCenter.default.post(name: .didUploadVideo, object: nil, userInfo: parseJSON as? [String: Any])
                    }
                } catch {
                    return
                }
            })
        self.removeActivityIndicator(activityIndicator: myActivityIndicator)
    }
    
    
    // MARK: Remove Activity Indicator
    func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
        DispatchQueue.main.async {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }

}
extension AVAsset {
    // MARK: Generate thumbnail (for user viewing)
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
extension UIImage {
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }

        return self
    }
}
