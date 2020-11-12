//
//  FirstViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import UserNotifications
import AsyncDisplayKit
import Alamofire

class HomeViewController: UIViewController, UIAdaptivePresentationControllerDelegate, UIScrollViewDelegate, ChannelVideoOverlayViewDelegate {
    
    
    // MARK: Tap for channel from overlay
    func didTapChannel(_ view: ChannelVideoOverlayView, videousername: String) {
        showUserChannel(videoUsername: videousername)
    }
    
    
    // MARK: Tap for comments from overlay
    func didTapComments(_ view: ChannelVideoOverlayView, videoid: Int) {
        showVideoComments(videoId: videoid)
    }
    
    
    // MARK: Get Videos For Home Page
    func getRandomVideos() {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let parameters = ["page" : "\(currentPage)"]
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("http://10.0.0.2:3000/api/v1/apihomefeed.json", method: .post, parameters: parameters, headers: headers).responseJSON { response in
            guard let data = response.data else {
                print("error code: 1kdm03o4-2")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedVideo = try decoder.decode(Videos.self, from: data)
                self.videos = downloadedVideo.videos + self.videos
                DispatchQueue.main.async {
                    self.tableNode.reloadData()
                }
            } catch {
                print("error code: 1kzka0aww3-2")
                return
            }
        }
    }
    
    
    // MARK: Batch Fetch Request
    func batchFetch(success: @escaping (_ response: AFDataResponse<Any>?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        guard let token: String = try? tokenValet.string(forKey: "Token") else { return }
        let parameters = ["page" : "\(currentPage)"]
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json"
        ]
        AF.request("http://10.0.0.2:3000/api/v1/apihomefeed.json", method: .post, parameters: parameters, headers: headers).responseJSON { response in
            switch response.result {
            case .success:
                success(response)
            case .failure(let error):
                failure(error as NSError)
            }
            
        }
    }
    

    // MARK: Function for showing user channel
    func showUserChannel(videoUsername: String) {
        self.videoUsername = videoUsername
        self.performSegue(withIdentifier: "showHomeVideoUserChannel", sender: self)
    }
    
    // MARK: Function for showing video comments
    func showVideoComments(videoId: Int) {
        self.videoId = videoId
        self.performSegue(withIdentifier: "showHomeVideoComments", sender: self)
        
    }
    
    
    // MARK: Table node frame
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableNode.frame = self.view.bounds
    }
    
    
    // MARK: Segue Data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let vc = segue.destination as? CommentingViewController {
            if segue.identifier == "showHomeVideoComments" {
                vc.presentationController?.delegate = self
                vc.videoId = videoId
            }
        } else if let vc = segue.destination as? OtherChannelViewController {
            if segue.identifier == "showHomeVideoUserChannel" {
                vc.chanelVar = videoUsername
            }
        }
    }
    
    // MARK: Variables
    var window: UIWindow?
    var videoId = Int()
    var videoUsername = String()
    var tableNode: ASTableNode!
    var lastNode: ChannelVideoCellNode?
    private var videos = [Video]()
    var currentPage: Int = 1
    
    
    // MARK: Videos downloaded
    class Videos: Codable {
        let videos: [Video]
        init(videos: [Video]) {
            self.videos = videos
        }
    }
    
    class Video: Codable {
        let videourl: String
        let videoid: Int
        init(videourl: String, videoid: Int) {
            self.videourl = videourl
            self.videoid = videoid
        }
    }

    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: Delegates
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    
    // MARK: Styling for table node
    func applyStyle() {
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.isPagingEnabled = true
    }
    
    // MARK: Delegates for table node
    func wireDelegates() {
        self.tableNode.delegate = self
        self.tableNode.dataSource = self
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        try! AVAudioSession.sharedInstance().setCategory(.playback, options: [])
        self.tableNode = ASTableNode(style: .plain)
        self.wireDelegates()
        self.view.insertSubview(tableNode.view, at: 0)
        self.applyStyle()
        self.tableNode.leadingScreensForBatching = 1.0
        getRandomVideos()
        checkUser() // This doesn't have to be the first thing
    }
    
    
    // MARK: Check user's account to make sure it's valid
    func checkUser() {
        guard let accessToken: String = try? tokenValet.string(forKey: "Token") else { return }
        guard let userId: String = try? myValet.string(forKey: "Id") else { return }
        guard let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/isuservalid/\(userId)") else { return }
        var request = URLRequest(url:myUrl)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                print("there is an error")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let status: String? = parseJSON["status"] as? String
                    switch status {
                    case "User is valid! YAY :)":
                        return
                    case "User is not valid. Oh no!":
                        try self.myValet.removeObject(forKey: "Id")
                        try self.tokenValet.removeObject(forKey: "Token")
                        try self.myValet.removeAllObjects()
                        try self.tokenValet.removeAllObjects()
                        let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                        self.present(loginPage, animated:false, completion:nil)
                        self.window =  UIWindow(frame: UIScreen.main.bounds)
                        self.window?.rootViewController = loginPage
                        self.window?.makeKeyAndVisible()
                    case .none:
                        break
                    case .some(_):
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 404 {
                                try self.myValet.removeObject(forKey: "Id")
                                try self.tokenValet.removeObject(forKey: "Token")
                                try self.myValet.removeAllObjects()
                                try self.tokenValet.removeAllObjects()
                                DispatchQueue.main.async {
                                    let loginPage = self.storyboard?.instantiateViewController(identifier: "AuthenticateViewController") as! AuthenticateViewController
                                    self.window =  UIWindow(frame: UIScreen.main.bounds)
                                    self.present(loginPage, animated: true, completion: nil)
                                    self.window?.rootViewController = loginPage
                                }
                            }
                        } else {
                            break
                        }
                    }
                } else {
                    return
                }
            } catch {
                return
            }
        }
        task.resume()
    }
    
    
    // MARK: New rows for table node
    func insertNewRowsInTableNode(newVideos: [Video]) {
        guard newVideos.count > 0 else {
            return
        }
        let section = 0
        var indexPaths: [IndexPath] = []
        let total = self.videos.count + newVideos.count
        for row in self.videos.count...total-1 {
            let path = IndexPath(row: row, section: section)
            indexPaths.append(path)
        }
        self.videos.append(contentsOf: newVideos)
        self.tableNode.insertRows(at: indexPaths, with: .none)
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
extension HomeViewController: ASTableDataSource {
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.videos.count
    }
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let videourll = self.videos[indexPath.row].videourl
        let videoId = self.videos[indexPath.row].videoid
        let videoUrl = URL(string: "http://10.0.0.2:3000\(videourll)")
        return {
            let node = ChannelVideoCellNode(with: videoUrl!, videoId: videoId, doesParentHaveTabBar: true)
            node.delegate = self
            node.debugName = "\(self.videos[indexPath.row].videoid)"
            return node
        }
    }
}
extension HomeViewController: ASTableDelegate {
    // MARK: Size of each cell
    func tableNode(_ tableNode: ASTableNode, constrainedSizeForRowAt indexPath: IndexPath) -> ASSizeRange {
        let width = UIScreen.main.bounds.size.width
        let min = CGSize(width: width, height: (UIScreen.main.bounds.size.height/3) * 2)
        let max = CGSize(width: width, height: .infinity)
        return ASSizeRangeMake(min, max)
    }
    
    // MARK: Batch fetch bool
    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        return true
    }
    
    // MARK: Batch fetch function
    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        currentPage = currentPage + 1
        self.batchFetch(success: {(response) -> Void in
            guard let data = response?.data else {
                print("error code: 1kdm03o4-2")
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedVideo = try decoder.decode(Videos.self, from: data)
                let videos = downloadedVideo.videos + self.videos
                self.videos = videos
                if self.videos.count != 0 {
                    DispatchQueue.main.async {
                        self.tableNode.reloadData()
                    }
                }
            } catch {
                print("error code: 1kzka0aww3-2")
                return
            }
        }, failure: { (error) -> Void in
            print("error code: 1kd03l103-2")
            print(error as Any)
        })
        context.completeBatchFetching(true)
    }

    
}
