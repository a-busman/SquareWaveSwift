//
//  RootViewController.swift
//  Square Wave
//
//  Created by Alex Busman on 2/25/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

class RootViewController: UISplitViewController, UISplitViewControllerDelegate, FileEngineDelegate {
    let reloadBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshPressed))
    let addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPressed))
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    var activityIndicatorBarButtonItem: UIBarButtonItem!
    let selectionGenerator = UISelectionFeedbackGenerator()
    let notificationGenerator = UINotificationFeedbackGenerator()
    
    func progress(_ currentIndex: UInt, total: UInt) {
        NSLog("\(currentIndex) out of \(total)")
    }
    
    func complete() {
        NSLog("Done!")
        self.notificationGenerator.notificationOccurred(.success)
        self.setBarItems(self.reloadBarButtonItem)
    }
    
    func failed(_ error: Error) {
        NSLog("Failed!")
        self.notificationGenerator.notificationOccurred(.error)
        self.setBarItems(self.reloadBarButtonItem)
    }
    
    var cancellable: AnyCancellable?
    var navController = UINavigationController()
    var libraryController: UIViewController!
    var splitController = UISplitViewController()
    
    func setBarItems(_ barItem: UIBarButtonItem) {
        self.libraryController.navigationItem.setRightBarButtonItems([
            barItem,
            self.addBarButtonItem
        ], animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.preferredDisplayMode = .allVisible
        self.preferredPrimaryColumnWidthFraction = 1 / 3
        self.selectionGenerator.prepare()
        self.notificationGenerator.prepare()
        
        self.activityIndicatorBarButtonItem = UIBarButtonItem(customView: self.activityIndicator)
        self.activityIndicator.startAnimating()
        FileEngine.reloadFromCloud(with: self)

        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        self.libraryController = UIHostingController(rootView: LibraryView().environment(\.managedObjectContext, context).environmentObject(AppDelegate.playbackState))

        self.navController = UINavigationController(rootViewController: self.libraryController)
        
        self.navController.navigationBar.prefersLargeTitles = true
        
        self.libraryController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(settingsPressed))
        
        self.setBarItems(self.activityIndicatorBarButtonItem)
        
        
        let miniDelegate = NowPlayingMiniViewDelegate()
        let miniViewController = UIHostingController(rootView: NowPlayingMiniView(delegate: miniDelegate).environmentObject(AppDelegate.playbackState))
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            let npController = UIHostingController(rootView: NowPlayingView().environmentObject(AppDelegate.playbackState))
            self.cancellable = miniDelegate.didChange.sink { _ in
                self.present(npController, animated: true)
            }
        
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
            blurView.translatesAutoresizingMaskIntoConstraints = false
            let blurContentView = blurView.contentView
            
            let miniView = miniViewController.view!
            miniView.backgroundColor = .clear
            
            blurContentView.addSubview(miniView)
            miniView.translatesAutoresizingMaskIntoConstraints = false
            miniView.topAnchor.constraint(equalTo: blurContentView.topAnchor).isActive = true
            miniView.bottomAnchor.constraint(equalTo: blurContentView.bottomAnchor).isActive = true
            miniView.leadingAnchor.constraint(equalTo: blurContentView.leadingAnchor).isActive = true
            miniView.trailingAnchor.constraint(equalTo: blurContentView.trailingAnchor).isActive = true
            
            self.view.addSubview(blurView)

            blurView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            blurView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -75.0).isActive = true
            blurView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            blurView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        }
        
        var npController = UIViewController()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            npController = UIHostingController(rootView: NowPlayingView(showsHandle: false).environmentObject(AppDelegate.playbackState))
        }
        self.viewControllers = [self.navController, npController]
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    @objc func settingsPressed(sender: UIBarButtonItem) {
        let settingsView = UIHostingController(rootView: SettingsView(dismiss: {self.dismiss(animated: true, completion: nil)}).environmentObject(AppDelegate.playbackState))
        self.present(settingsView, animated: true)
    }
    
    @objc func refreshPressed(sender: UIBarButtonItem) {
        self.selectionGenerator.selectionChanged()
        self.setBarItems(self.activityIndicatorBarButtonItem)
        FileEngine.reloadFromCloud(with: self)
    }
    
    @objc func addPressed(sender: UIBarButtonItem) {
        self.selectionGenerator.selectionChanged()
        let controller = UIHostingController(rootView: FilePicker())
        self.present(controller, animated: true)
    }
}
