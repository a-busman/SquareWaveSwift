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

class RootViewController: UIViewController {
    var cancellable: AnyCancellable?
    var navController = UINavigationController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        let libraryController = UIHostingController(rootView: LibraryView().environment(\.managedObjectContext, context).environmentObject(AppDelegate.playbackState))
        
        self.navController = UINavigationController(rootViewController: libraryController)
        
        self.navController.navigationBar.prefersLargeTitles = true
        
        libraryController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(settingsPressed))
        
        libraryController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPressed))
        
        self.view.insertSubview(self.navController.view, at: 0)
        let view = self.navController.view
        
        view?.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        view?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        view?.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        view?.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
    
    @IBSegueAction func addSwiftUIView(coder: NSCoder) -> UIViewController? {
        let delegate = NowPlayingMiniViewDelegate()
        let controller = UIHostingController(coder: coder, rootView: NowPlayingMiniView(delegate: delegate).environmentObject(AppDelegate.playbackState))
        
        self.cancellable = delegate.didChange.sink { (delegate) in
            let controller = UIHostingController(rootView: NowPlayingView().environmentObject(AppDelegate.playbackState))
            self.present(controller, animated: true)
        }
        
        return controller
    }
    
    @objc func settingsPressed(sender: UIBarButtonItem) {
        let settingsView = UIHostingController(rootView: SettingsView(dismiss: {self.dismiss(animated: true, completion: nil)}).environmentObject(AppDelegate.playbackState))
        self.present(settingsView, animated: true)
    }
    
    @objc func addPressed(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add files", message: nil, preferredStyle: .actionSheet)
        
        let fromFolderAction = UIAlertAction(title: "From folder...", style: .default, handler: { _ in
            let controller = UIHostingController(rootView: FilePicker(folderType: true))
            self.present(controller, animated: true)
        })
        
        let fromFilesAction = UIAlertAction(title: "From files...", style: .default, handler: { _ in
            let controller = UIHostingController(rootView: FilePicker(folderType: false))
            self.present(controller, animated: true)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(fromFolderAction)
        alertController.addAction(fromFilesAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }
}
