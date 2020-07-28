//
//  ChannelViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Nuke
import Alamofire

class ChannelViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDataSource { // Look at youself. Look at what you have done.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    private let refreshControl = UIRefreshControl()
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Need to add something here to make it compile
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChannelVideoCell", for: indexPath) as? ChannelVideoCell else { return UICollectionViewCell() }
        let Id: Int? = videos[indexPath.row].id
        
        cell.thumbnailView.image = UIImage(named: "load-image")
        
        AF.request("http://10.0.0.2:3000/api/v1/videoinfo/\(Id!).json").responseJSON { response in
            var JSON: [String: Any]?
            do {
                JSON = try JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                let imageUrl = JSON!["thumbnail_url"] as? String
                let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl!)")
                guard let imageURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("load-image") else {
                    return
                }
                DispatchQueue.main.async {
                    Nuke.loadImage(with: railsUrl ?? imageURL, into: cell.thumbnailView)
                }
            } catch {
                self.showErrorContactingServer()
            }
        }
        
        return cell
    }
    func seeVideo() {
        self.performSegue(withIdentifier: "showVideo", sender: self)
    }
    func collectionView(CollectionView: UICollectionView, didSelectRowAt indexPath: IndexPath) {
        let destinationVC = ChannelVideoViewController()
        destinationVC.performSegue(withIdentifier: "showVideo", sender: self)
    }
    @IBOutlet weak var collectionView: UICollectionView!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard let userId: String  = try? myValet.string(forKey: "Id") else { return }
        if segue.destination is ChannelVideoViewController
        {
            if let vc = segue.destination as? ChannelVideoViewController {
                if segue.identifier == "showVideo" {
                    if let indexPath = collectionView?.indexPathsForSelectedItems?.first {
                        let selectedRow = indexPath.row
                        vc.videoString = videos[selectedRow].id
                    }
                }
            }
        } else if segue.destination is OtherFollowerListViewController
        {
            if let vc = segue.destination as? OtherFollowerListViewController {
                if segue.identifier == "showChannelFollowerList" {
                    vc.followerVar = userId
                }
            }
        } else if segue.destination is OtherFollowListViewController {
            if let vc = segue.destination as? OtherFollowListViewController {
                if segue.identifier == "showFollowList" {
                    vc.followingVar = userId
                }
            }
        }
    }
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)

    @IBAction func settingsButtonTap(_ sender: Any) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let lineView = UIView(frame: CGRect(x: 0, y: 240, width: self.view.frame.size.width, height: 1))
        if traitCollection.userInterfaceStyle == .light {
            lineView.backgroundColor = UIColor.black
        } else {
            lineView.backgroundColor = UIColor.white
        }
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshVideos(_:)), for: .valueChanged)
        self.view.addSubview(lineView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.imageTapped(gesture:)))
        avatarImage.isUserInteractionEnabled = true
        ImageCache.shared.ttl = 120
        avatarImage.addGestureRecognizer(tapGesture)
        self.followersLabel.isUserInteractionEnabled = true
        self.followingLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.tapFunction))
        let tapp = UITapGestureRecognizer(target: self, action: #selector(ChannelViewController.tappFunction))
        followersLabel.addGestureRecognizer(tap)
        followingLabel.addGestureRecognizer(tapp)
        loadMemberChannel()
        channelVideoIds()
        self.avatarImage.contentScaleFactor = 1.5
        // Setup the view so you can integerate it right away with the channel api.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadMemberChannel()
        channelVideoIds()
    }
    @objc private func refreshVideos(_ sender: Any) {
        channelVideoIds()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            pickAvatar()
        }
    }
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        goToFollowersList()
    }
    @objc func tappFunction(sender:UITapGestureRecognizer) {
        goToFollowingList()
    }
    func goToFollowersList() {
        self.performSegue(withIdentifier: "showChannelFollowerList", sender: self)
    }
    func goToFollowingList() {
        self.performSegue(withIdentifier: "showFollowList", sender: self)
    }
    class Videos: Codable {
        let videos: [Video]
        init(videos: [Video]) {
            self.videos = videos
        }
    }
    class Video: Codable {
        let id: Int
        init(username: String, name: String, id: Int) {
            self.id = id // Pass id through a seuge to channelvideo
        }
    }
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    private var videos = [Video]()
    // MARK: Load the channel's videos
    func channelVideoIds() { // Still not done we need to add the user's butt image
        guard let userId: String  = try? myValet.string(forKey: "Id") else { return }
        guard let Id = Int(userId) else { return }
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id).json")  // 23:40
            guard let downloadURL = url else { return }
            URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
                guard let data = data, error == nil, urlResponse != nil else {
                    self.showNoResponseFromServer()
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let downloadedVideo = try decoder.decode(Videos.self, from: data)
                    self.videos = downloadedVideo.videos
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } catch {
                    self.showErrorContactingServer() // f
                }
            }.resume()
    }
    // MARK: Load the channel's info
    func loadMemberChannel() {
        guard let userId: String  = try? myValet.string(forKey: "Id") else { return }
        guard let Id = Int(userId) else { return }
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id).json")
            var request = URLRequest(url:myUrl!)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                if error != nil {
                    self.showErrorContactingServer()
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                    if let parseJSON = json {
                        let username: String? = parseJSON["username"] as? String
                        let name: String? = parseJSON["name"] as? String
                        let imageUrl: String? = parseJSON["avatar_url"] as? String
                        guard let followerCount: Int = parseJSON["followers_count"] as? Int else { return }
                        guard let followingCount: Int = parseJSON["following_count"] as? Int else { return }
                        let bio: String? = parseJSON["bio"] as? String
                        let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                        if bio?.isEmpty != true {
                            DispatchQueue.main.async {
                                self.bioLabel.text = bio ?? ""
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.bioLabel.text = String("")
                            }
                        }
                        if username?.isEmpty != true && name?.isEmpty != true {
                            DispatchQueue.main.async {
                                self.usernameLabel.text = username ?? ""
                                self.nameLabel.text = name ?? ""
                            }
                        } else {
                            self.showNoResponseFromServer()
                        }
                        switch followerCount {
                        case _ where followerCount < 1000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount)"
                            }
                        case _ where followerCount > 1000 && followerCount < 100000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount/1000).\((followerCount/100)%10)k" }
                        case _ where followerCount > 100000 && followerCount < 1000000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount/1000)k"
                            }
                        case _ where followerCount > 1000000 && followerCount < 100000000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount/1000000).\((followerCount/1000)%10)M"
                            }
                        case _ where followerCount > 100000000:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount/1000000)M"
                            }
                        default:
                            DispatchQueue.main.async {
                                self.followersLabel.text = "\(followerCount )"
                            }
                        }
                        switch followingCount {
                        case _ where followingCount < 1000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount)"
                            }
                        case _ where followingCount > 1000 && followingCount < 100000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount/1000).\((followingCount/100)%10)k" }
                        case _ where followingCount > 100000 && followingCount < 1000000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount/1000)k"
                            }
                        case _ where followingCount > 1000000 && followingCount < 100000000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount/1000000).\((followingCount/1000)%10)M"
                            }
                        case _ where followingCount > 100000000:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount/1000000)M"
                            }
                        default:
                            DispatchQueue.main.async {
                                self.followingLabel.text = "\(followingCount)"
                            }
                        }
                        DispatchQueue.main.async {
                            Nuke.loadImage(with: railsUrl!, into: self.avatarImage)
                        }
                    } else {
                        self.showErrorContactingServer()
                    }
                } catch {
                        self.showNoResponseFromServer()
                    }
            }
            task.resume()
    } // I will set this up later
    // MARK: Import image for avatar
    func importImage() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    // MARK: Upload avatar image
    func upload() {
        let token: String?  = try? self.tokenValet.string(forKey: "Token")
        let userId: String?  = try? self.myValet.string(forKey: "Id")
        let Id = Int(userId!)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        let url = String("http://10.0.0.2:3000/api/v1/registrations/\(Id!)")
        let image = avatarImage.image///haha im small
        // let image = [UIImagePickerController.InfoKey.editedImage]
        guard let imgcompressed = image!.jpegData(compressionQuality: 0.5) else { return }
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imgcompressed, withName: "avatar" , fileName: "\(Id!)-avatar.png", mimeType: "image/png")
        },
            to: url, method: .patch , headers: headers)
            .response { resp in
                print(resp)


        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            avatarImage.image = image
            upload()
        } else {
            self.showUnkownError()
        }
        self.dismiss(animated: true, completion: nil)
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    // MARK: Take picture for avatar
    func takePicture() {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.camera
        image.allowsEditing = true
        self.present(image, animated: true) {
            
        }
    }
    
    func showErrorContactingServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "Error contacting the server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showNoResponseFromServer() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "No response from server. Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    func showUnkownError() {

        // create the alert
        let alert = UIAlertController(title: "Error", message: "We don't know what happend wrong here! Try again later.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "Fine", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    func pickAvatar() {
            let alert = UIAlertController(title: "Avatar", message: "Change your avatar.", preferredStyle: UIAlertController.Style.actionSheet)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "Pick from gallery", style: UIAlertAction.Style.default, handler: { action in
                print("Pick from gallery")
                self.importImage()
            }))
            alert.addAction(UIAlertAction(title: "Take photo", style: UIAlertAction.Style.default, handler: { action in
                print("Take photo")
                self.takePicture()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
