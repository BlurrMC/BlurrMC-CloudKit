//
//  OtherFollowerListViewController.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/19/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import Valet
import Nuke

class OtherFollowerListViewController: UIViewController, UITableViewDataSource {
    
    // MARK: Outlets
    @IBOutlet weak var nothingHereLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Variables:
    var followerVar = String()
    private var followers = [Follower]()
    var followerId = String()
    
    
    // MARK: Valet
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    // MARK: Lets
    private let refreshControl = UIRefreshControl()
    
    
    // MARK: Back Button Tap
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadJson()
        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshFollowers(_:)), for: .valueChanged)
    }
    
    
    // MARK: Memory Warning Clear
    override func didReceiveMemoryWarning() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    
    // MARK: Refresh Followers Function
    @objc private func refreshFollowers(_ sender: Any) {
        downloadJson() 
    }
    
    
    // MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    
    // MARK: View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        downloadJson()
    }
    
    
    // MARK: Download the user's followers
    func downloadJson() { // Still not done we need to add the user's butt image
        let Id = followerVar
        followerId = Id
        let url = URL(string: "http://10.0.0.2:3000/api/v1/channelsfollowers/\(followerId).json")  // 23:40
        guard let downloadURL = url else { return }
        URLSession.shared.dataTask(with: downloadURL) { (data, urlResponse, error) in
            guard let data = data, error == nil, urlResponse != nil else {
                self.showNoResponseFromServer()
                return
            }
            do {
                let decoder = JSONDecoder()
                let downloadedFollower = try decoder.decode(Followers.self, from: data)
                self.followers = downloadedFollower.followers
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                return
            }
        }.resume()
    }
    
    
    // MARK: Followers Downloaded From JSON
    class Followers: Codable {
        let followers: [Follower]
        init(followers: [Follower]) {
            self.followers = followers
        }
    }
    class Follower: Codable {
        let username: String
        let name: String
        let id: Int
        init(username: String, name: String, id: Int) {
            self.username = username
            self.name = name
            self.id = id
        }
    }
    
    
    // MARK: Number Of Rows In Section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followers.count
    }
    
    
    // MARK: Cell For Row At
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "OtherFollowerCell") as? OtherFollowerCell else { return UITableViewCell() }
        cell.followerUsername.text = followers[indexPath.row].username // Hey stupid if you want to add more just add one more line of code here
        cell.followerName.text = followers[indexPath.row].name
        print("\(followers[indexPath.row].name)")
            if cell.followerUsername.text == nil {
                DispatchQueue.main.async {
                    self.nothingHereLabel.text = String("Nothing Here")
                }
            } else {
                DispatchQueue.main.async {
                    self.nothingHereLabel.text = String("")
                }
            }
        let Id: Int? = followers[indexPath.row].id
        let myUrl = URL(string: "http://10.0.0.2:3000/api/v1/channels/\(Id!).json")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                if let parseJSON = json {
                    let imageUrl: String? = parseJSON["avatar_url"] as? String
                    let railsUrl = URL(string: "http://10.0.0.2:3000\(imageUrl ?? "/assets/fallback/default-avatar-3.png")")
                    DispatchQueue.main.async {
                        Nuke.loadImage(with: railsUrl!, into: cell.followerAvatar)
                        }
                } else {
                    return
                }
            } catch {
                print(error)
                return
            }
        }
        task.resume()
        return cell
    }
    
    
    // MARK: Did Select Row
    func tableView(tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destinationVC = OtherChannelViewController()
        destinationVC.performSegue(withIdentifier: "showChannel", sender: self)
    }
    
    
    // MARK: Pass Info Through Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow{
            let selectedRow = indexPath.row
            let detailVC = segue.destination as! OtherChannelViewController
            detailVC.chanelVar = followers[selectedRow].username
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
}
