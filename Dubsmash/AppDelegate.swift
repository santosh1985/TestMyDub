//
//  AppDelegate.swift
//  Dubsmash
//
//  Created by Santosh Pawar on 6/13/17.
//  Copyright © 2017 onest. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //Create our own 'window' to display something in it since we are not using Storyboards.
        window = UIWindow(frame: UIScreen.main.bounds)
        
        //Now we have our Window, create a first viewController of our app.
        let homeViewController = DUBHomeViewController()
        
        //Now add this VC to our window
        if let window = window {
            
            let navigationController = UINavigationController(rootViewController: homeViewController)
            navigationController.navigationBar.isTranslucent = false
            window.rootViewController = navigationController
            window.makeKeyAndVisible()

            //now show our window on the screen
            window.makeKeyAndVisible()
        }
        
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {

        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "Dubsmash")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
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
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

