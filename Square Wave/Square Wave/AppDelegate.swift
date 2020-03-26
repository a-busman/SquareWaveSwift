//
//  AppDelegate.swift
//  Square Wave
//
//  Created by Alex Busman on 2/10/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit
import CoreData
import Firebase

@UIApplicationMain
@objcMembers
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var playbackState = PlaybackState()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        FirebaseApp.configure()
        
        var purchased: Bool? = PlaybackStateProperty.purchased.getProperty()
        
        if purchased != true {
            if let product = IAPManager.shared.getProductIDs()?.first {
                let iap = UserDefaults.standard.bool(forKey: product)
                if iap == true {
                    PlaybackStateProperty.purchased.setProperty(newValue: true)
                    AppDelegate.playbackState.restricted = false
                    AppDelegate.playbackState.purchased = true
                    purchased = true
                } else {
                    PlaybackStateProperty.purchased.setProperty(newValue: false)
                }
            }
        }
        if purchased != true {
            let receiptFetcher = ReceiptFetcher()
            
            receiptFetcher.fetchReceipt()
            
            let receiptValidator = ReceiptValidator()
            let validationResult = receiptValidator.validateReceipt()
            
            switch validationResult {
            case .success(let receipt):
                self.grantPremiumToPreviousUser(receipt: receipt)
            case .error(let error):
                Analytics.logEvent("invalidReceipt", parameters: ["error" : error.localizedDescription])
            }
        }
        IAPManager.shared.startObserving()
        self.createDirectories()
        
        return true
    }
    
    func grantPremiumToPreviousUser(receipt: ParsedReceipt) {
        // cast the string into integer (build number)
        guard let originalAppVersionString = receipt.originalAppVersion,
              let originalBuildNumber = Int(originalAppVersionString) else {
                Analytics.logEvent("appVersionFailedParse", parameters: ["appVersionString" : receipt.originalAppVersion ?? "N/A"])
            return
        }
        
        // the last build number that the app is still a paid app
        if originalBuildNumber < 10 {
            PlaybackStateProperty.purchased.setProperty(newValue: true)
            AppDelegate.playbackState.restricted = false
            AppDelegate.playbackState.purchased = true
        }
    }
    
    static func updatePlaybackState(hasTracks: Bool) {
        AppDelegate.playbackState.objectWillChange.send()
        AppDelegate.playbackState.hasTracks = hasTracks
    }
    
    static func getCurrentPlayingTrack() -> Track? {
        return AppDelegate.playbackState.nowPlayingTrack
    }
    
    static func clearCurrentTrackList() {
        AppDelegate.playbackState.stop()
        AppDelegate.playbackState.currentTracklist = []
        AppDelegate.playbackState.nowPlayingTrack = nil
        AppDelegate.playbackState.trackNum = 0
    }
    
    static func removeTrackFromTracklist(_ track: Track) {
        guard let index = AppDelegate.playbackState.currentTracklist.firstIndex(of: track) else {
            return
        }
        AppDelegate.playbackState.currentTracklist.remove(at: index)
        if AppDelegate.playbackState.nowPlayingTrack == track {
            AppDelegate.playbackState.stop()
            AppDelegate.playbackState.nowPlayingTrack = nil
            AppDelegate.playbackState.trackNum = 0
        }
    }
    
    func createDirectories() {
        if let playlistImagesDir = Util.getPlaylistImagesDirectory() {
            if !FileManager.default.fileExists(atPath: playlistImagesDir.path) {
                do {
                    try FileManager.default.createDirectory(at: playlistImagesDir, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    Analytics.logEvent("createImagesErr", parameters: ["error" : error.localizedDescription])
                    NSLog("Could not create playlist images directory. \(error.localizedDescription)")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        FileEngine.addFile(url, removeOriginal:true)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        IAPManager.shared.stopObserving()
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Square_Wave")
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
                FileEngine.clearDatabase()
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

}

