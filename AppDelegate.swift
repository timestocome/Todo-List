//
//  AppDelegate.swift
//  GenericListWithSyncing
//
//  Created by Linda Cobb on 11/20/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import UIKit
import CoreData


@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate
{

    var window: UIWindow?
    let stack = CoreDataStack()
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationControllers = splitViewController.viewControllers as! [UINavigationController]
        
        let navigationController = splitViewController.viewControllers[1] as! UINavigationController
        navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self

        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        let controller = masterNavigationController.topViewController as! MasterViewController
        
        // iCloud notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "iCloudNotificationArrived:",
            name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: nil)
        
        return true
    }
    
    
    
    
    func iCloudNotificationArrived (notification: NSNotification ){
        
        var error: NSError? = nil
        
        // get current status
        let defaults = NSUserDefaults.standardUserDefaults()
        let cloudOn = defaults.objectForKey("cloudOn") as! Int

    
            if cloudOn == 1 {
                let managedObjectContext = stack.cloudManagedObjectContext
        
                if managedObjectContext?.hasChanges != nil   {
                    managedObjectContext?.save(&error)
                }
            }
        
    }
    

    
    func loadCloudOrLocalDatabase() ->NSManagedObjectContext {
        
        // get current status
        var managedObjectContext:NSManagedObjectContext
        let defaults = NSUserDefaults.standardUserDefaults()
        let cloudOn = defaults.objectForKey("cloudOn") as! Int
        
       
        if cloudOn == 1 {
                return stack.cloudManagedObjectContext!
        }else{
                return stack.localManagedObjectContext!
        }
    }
    
    
    
    
    func applicationWillEnterForeground(application: UIApplication) {}
    
    
    func applicationDidBecomeActive(application: UIApplication) {
    
        loadCloudOrLocalDatabase()

    }
    
    
    func applicationWillResignActive(application: UIApplication) { saveContext()  }
    func applicationDidEnterBackground(application: UIApplication) { saveContext() }
   
    func applicationWillTerminate(application: UIApplication) { saveContext() }

    
    

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController!, ontoPrimaryViewController primaryViewController:UIViewController!) -> Bool {
       
        if let secondaryAsNavController = secondaryViewController as? UINavigationController {
            if let topAsDetailController = secondaryAsNavController.topViewController as? ListItemsViewController {
                return true
            }
        }
        
        return false
    }
    
    
    
    
    
    func saveContext () {
        
        if let moc = stack.localManagedObjectContext as NSManagedObjectContext? {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSLog("Unresolved save error \(error), \(error!.userInfo)")
            }
        }
        
        if let moc = stack.cloudManagedObjectContext as NSManagedObjectContext? {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSLog("Unresolved save error \(error), \(error!.userInfo)")
            }
        }
    }

    
    
    
    

}

