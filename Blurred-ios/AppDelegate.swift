//
//  AppDelegate.swift
//  Blurred-ios
//
//  Created by Martin Velev on 4/21/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit
import CoreData
import Valet
import AVFoundation
import Alamofire
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    public var isItLoading: Bool = false
    var documentsUrl: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    let myValet = Valet.valet(with: Identifier(nonEmpty: "Id")!, accessibility: .whenUnlocked)
    let tokenValet = Valet.valet(with: Identifier(nonEmpty: "Token")!, accessibility: .whenUnlocked)
    
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        } catch {
            print("AVAudioSessionCategoryPlayback not work")
        }
    }
    
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "Blurred_ios")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let accessToken: String? = try? tokenValet.string(forKey: "Token")
        let userId: String? = try? myValet.string(forKey: "Id")
        requestNotificationAuthorization()
        if accessToken != nil && userId != nil {
            let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            self.window =  UIWindow(frame: UIScreen.main.bounds)
            let homePage = storyboard.instantiateViewController(withIdentifier: "MainTabBarViewController") as! MainTabBarViewController
            if(launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] != nil){
                homePage.selectedIndex = 3
            }
            self.window?.rootViewController = homePage
            return finishLoadingHomepage()
        }
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 50
        return true
    }
    
    // MARK: Finish loading homepage
    func finishLoadingHomepage() -> Bool {
        self.window?.makeKeyAndVisible()
        self.isItLoading = true
        return true
    }
    
    
    // MARK: Register For Notifications
    func requestNotificationAuthorization(){
        UNUserNotificationCenter.current() .requestAuthorization( options: [.alert, .sound, .badge]) { [weak self] granted, error in
            guard granted else { return }
            self?.getNotificationSettings()
        }
    }
    
    // MARK: Received Notification
    private func application(application: UIApplication,  didReceiveRemoteNotification userInfo: [NSObject : AnyObject],  fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        completionHandler(.newData)
    }
    
    
    // MARK: Get Notification Settings
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        try? self.tokenValet.setString(token, forKey: "NotificationToken")
    }
    
    

    // If the user does not allow push notifications, this method will be called
    private func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("Error code: a04ewma, Failed to get token. Error: %@", error)
   }

}
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
          
        NotificationCenter.default.post(name: .notificationtap, object: "notificationtap")
        
        completionHandler()
    }

}

extension Notification.Name {
    static let notificationtap = Notification.Name("tapfromnotification")
}
