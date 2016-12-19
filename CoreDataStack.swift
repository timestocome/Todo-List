//
//  CoreDataStack.swift
//  BasicCloudSync
//
//  Created by Linda Cobb on 11/11/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import CoreData





class CoreDataStack
{
    
    let cloudOptions = [NSPersistentStoreUbiquitousContentNameKey: "Store",
                        NSMigratePersistentStoresAutomaticallyOption: true,
                        NSInferMappingModelAutomaticallyOption: true ]

    
    let localOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
                        NSInferMappingModelAutomaticallyOption: true ]


    lazy var applicationDocumentsDirectory: NSURL = {
      
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
        }()
    
    

    
    var managedObjectModel: NSManagedObjectModel = {

        let modelURL = NSBundle.mainBundle().URLForResource("ToDoList", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    
    
    
        
    
    func saveContext () {
        
        if let moc = localManagedObjectContext as NSManagedObjectContext? {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSLog("Unresolved save error \(error), \(error!.userInfo)")
            }
        }
        
        if let moc = cloudManagedObjectContext as NSManagedObjectContext? {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSLog("Unresolved save error \(error), \(error!.userInfo)")
            }
        }
    }

    
    
    
    func mergeChanges(notification: NSNotification) {
        
        cloudManagedObjectContext?.mergeChangesFromContextDidSaveNotification(notification)
        localManagedObjectContext?.mergeChangesFromContextDidSaveNotification(notification)
    }
    
    
    func swapDataStorageComplete(notification: NSNotification){
        localManagedObjectContext?.reset()
        cloudManagedObjectContext?.reset()
    }
    
    
    
    
    
    func moveLocalDataToCloud (){
    
        var error: NSError? = nil

        // save pending changes
        localManagedObjectContext?.save(&error)
        
        // migrate data
        let newURL = cloudStore().URL
        let newStore = cloudPersistentStoreCoordinator.migratePersistentStore(localStore(), toURL: newURL!, options: cloudOptions, withType: NSSQLiteStoreType, error: &error)

        // save updates
        cloudManagedObjectContext?.save(&error)
        
    }
    
    
    
    
    
    func moveCloudDataToLocal (){
    
        
        var error: NSError? = nil
        
        // save pending updates
        cloudManagedObjectContext?.save(&error)
        
        
        // migrate
        let newURL = localStore().URL
        var newStore = localPersistentStoreCoordinator.migratePersistentStore(cloudStore(), toURL: newURL!, options: localOptions, withType: NSSQLiteStoreType, error: &error)
        
        
        
        // remove cloud metaData
        var metaData = localPersistentStoreCoordinator.metadataForPersistentStore(localStore()) as Dictionary
        var iCloudKeys = metaData.keys
        
        for key in iCloudKeys {
            var appleKey = key as! NSString
            if  appleKey.containsString("com.apple.coredata.ubiquity") {
                metaData.removeValueForKey(appleKey)
            }
        }
        
        localStore().readOnly = false
        localPersistentStoreCoordinator.setMetadata(metaData, forPersistentStore: localStore())
        
        // save updates
        localManagedObjectContext?.save(&error)

        
    
    }
    
    
    
    
   
    
    
    
    func localStore () -> NSPersistentStore {
        return localPersistentStoreCoordinator.persistentStores[0]as! NSPersistentStore
    }
    
    
    func cloudStore () -> NSPersistentStore {
        return cloudPersistentStoreCoordinator.persistentStores[0]as! NSPersistentStore
    }
    
   
    
    
    func deDupLocal () {
        
        // get lists and sort by name, then date
        var error: NSError? = nil
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        var dateSort = NSSortDescriptor(key: "timeStamp", ascending: true)
        let moc = localManagedObjectContext
        var entity = NSEntityDescription.entityForName("TodoList", inManagedObjectContext: moc!)
        
        var fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [nameSort, dateSort]
        
        
        let sortedLists = moc?.executeFetchRequest(fetchRequest, error: &error)as! [TodoList]
        
      
        
        // compare and remove duplicated lists
        var count = sortedLists.count
        if count > 2 {
            for i in 1..<count {
            
                var firstList = sortedLists[i-1] as TodoList
                var secondList = sortedLists[i] as TodoList
            
                let firstName = firstList.valueForKey("name") as! NSString
                let firstDate = firstList.valueForKey("timeStamp") as! NSDate
            
                let secondName = secondList.valueForKey("name")as! NSString
                let secondDate = secondList.valueForKey("timeStamp")as! NSDate
            
                println("name \(firstName), \(secondName)")
            
                if firstName == secondName {
                    if firstDate == secondDate {
                    
                        moc?.deleteObject(firstList)
                 
                    }
                }
            }
        }

        
        // filter todos
        // get count for each todo name
        // if more than one keep newest
        // remove others
        dateSort = NSSortDescriptor(key: "date", ascending: true)
        entity = NSEntityDescription.entityForName("Todo", inManagedObjectContext: moc!)
        
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [nameSort, dateSort]
        
        
        let todos = moc?.executeFetchRequest(fetchRequest, error: &error)as! [Todo]
        
        
        count = todos.count
        if count > 2 {
            for i in 1..<count {
            
                var first = todos[i-1] as Todo
                var second = todos[i] as Todo
            
                let firstName = first.valueForKey("name") as! NSString
                let firstDate = first.valueForKey("date") as! NSDate
            
                let secondName = second.valueForKey("name") as! NSString
                let secondDate = second.valueForKey("date") as! NSDate
            
                if firstName == secondName {
                    if firstDate == secondDate {
                    
                        moc?.deleteObject(first)
                   
                    }
                }
            }
        }
        moc?.save(&error)
        

    }
    
    
    
    
    func deDupCloud () {
        
        // get lists and sort by name, then date
        var error: NSError? = nil
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        var dateSort = NSSortDescriptor(key: "timeStamp", ascending: true)
        let moc = cloudManagedObjectContext
        var entity = NSEntityDescription.entityForName("TodoList", inManagedObjectContext: moc!)
        
        var fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [nameSort, dateSort]
        
        
        let sortedLists = moc?.executeFetchRequest(fetchRequest, error: &error)as! [TodoList]
        
        
        
        // compare and remove duplicated lists
        var count = sortedLists.count
        if count > 2 {
            for i in 1..<count {
                
                var firstList = sortedLists[i-1] as TodoList
                var secondList = sortedLists[i] as TodoList
                
                let firstName = firstList.valueForKey("name") as! NSString
                let firstDate = firstList.valueForKey("timeStamp") as! NSDate
                
                let secondName = secondList.valueForKey("name") as! NSString
                let secondDate = secondList.valueForKey("timeStamp") as! NSDate
                
                println("name \(firstName), \(secondName)")
                
                if firstName == secondName {
                    if firstDate == secondDate {
                        
                        moc?.deleteObject(firstList)
                        
                    }
                }
            }
        }
        
        
        // filter todos
        // get count for each todo name
        // if more than one keep newest
        // remove others
        dateSort = NSSortDescriptor(key: "date", ascending: true)
        entity = NSEntityDescription.entityForName("Todo", inManagedObjectContext: moc!)
        
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [nameSort, dateSort]
        
        
        let todos = moc?.executeFetchRequest(fetchRequest, error: &error)as! [Todo]
        
        
        count = todos.count
        if count > 2 {
            for i in 1..<count {
                
                var first = todos[i-1] as Todo
                var second = todos[i] as Todo
                
                let firstName = first.valueForKey("name") as! NSString
                let firstDate = first.valueForKey("date") as! NSDate
                
                let secondName = second.valueForKey("name") as! NSString
                let secondDate = second.valueForKey("date") as! NSDate
                
                if firstName == secondName {
                    if firstDate == secondDate {
                        
                        moc?.deleteObject(first)
                        
                    }
                }
            }
        }
        moc?.save(&error)
        
        
    }

    
    
    
    
    lazy var localPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("ToDoList.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options:self.localOptions, error: &error) == nil {
            coordinator = nil
            
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
         //   error = NSError(domain: "EmailData persistentStore problem", code: 9999, userInfo: dic as [NSObject : AnyObject],t)
            println("psc error \(error)")
        }
        
        return coordinator!
        }()
    
    
    lazy var cloudPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("ToDoList.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        
        
        
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options:self.cloudOptions, error: &error) == nil {
            coordinator = nil
            
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
           // error = NSError(domain: "YOUR_ERROR_DOMAIN" as [NSObject : AnyObject]code: 9999, userInfo: dict)
            println("EmailData cloud psc problem")
        }
        
        return coordinator!
        }()
    
    
    
    
    
    lazy var backupPersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Backup.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
       
        
        
        
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options:self.localOptions, error: &error) == nil {
            coordinator = nil
            
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
           // error = NSError(domain: "Backup psc error",  as [NSObject : AnyObject]code: 9999, userInfo: dict)
        }
        
        return coordinator!
        }()
    
    
    
    
    lazy var localManagedObjectContext: NSManagedObjectContext? = {
        
        let coordinator = self.localPersistentStoreCoordinator
        
        if let coordinator = self.localPersistentStoreCoordinator as NSPersistentStoreCoordinator? {
            var managedObjectContext = NSManagedObjectContext()
            managedObjectContext.persistentStoreCoordinator = coordinator
            
            return managedObjectContext
        }else{
            return nil
        }
        }()
    
    
    
    
    lazy var cloudManagedObjectContext: NSManagedObjectContext? = {
        
        let coordinator = self.cloudPersistentStoreCoordinator
        
        if let coordinator = self.cloudPersistentStoreCoordinator as NSPersistentStoreCoordinator? {
            var managedObjectContext = NSManagedObjectContext()
            managedObjectContext.persistentStoreCoordinator = coordinator
            
            return managedObjectContext
        }else{
            return nil
        }
        }()
    
    
    
    lazy var backupManagedObjectContext: NSManagedObjectContext? = {
        
        let coordinator = self.backupPersistentStoreCoordinator
        
        if let coordinator = self.backupPersistentStoreCoordinator as NSPersistentStoreCoordinator? {
            var managedObjectContext = NSManagedObjectContext()
            managedObjectContext.persistentStoreCoordinator = coordinator
            
            return managedObjectContext
        }else{
            return nil
        }
        }()
    

}