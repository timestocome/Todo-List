//
//  InfoViewController.swift
//  GenericListWithSyncing
//
//  Created by Linda Cobb on 11/21/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MessageUI



// clean up orphaned items when deduping data


class InfoViewController: UIViewController, MFMailComposeViewControllerDelegate
{
    
    @IBOutlet weak var iCloudSwitch: UISwitch!
    let stack = CoreDataStack()
    
    
    let mailComposer = MFMailComposeViewController()

    // need for ipad to email a list
    @IBOutlet weak var shareView: UIView!

    
    let defaults = NSUserDefaults.standardUserDefaults()
    var cloudOn = 0
    
    
    
    override func viewWillAppear(animated: Bool) {
        
        // get current status
        
        cloudOn = defaults.objectForKey("cloudOn") as! Int
        
        if cloudOn == 1 {
            iCloudSwitch.setOn(true, animated:false)
        }else{
            iCloudSwitch.setOn(false, animated:false)
        }
        

        
        
        
        
        let frame = self.view.frame
        let backgroundView = UIImageView.init(frame:frame)
        let backgroundImage = UIImage(named: "paper.png")
        backgroundView.image = backgroundImage
        backgroundView.layer.zPosition = -1
        self.view.addSubview(backgroundView)
    
        mailComposer.mailComposeDelegate = self
        
    }
    
    
    

    
    
    @IBAction func iCloudOnOff (){
        
        
        // save current work
        stack.saveContext()
        
        // get current status
        let changeCloud = iCloudSwitch.on
        
        
        // switch existing preference and save
        if changeCloud == true {
    
            // move local data into cloud
            stack.moveLocalDataToCloud()
        }else{
            // move cloud data into local
            stack.moveCloudDataToLocal()
        }
            
        
        if changeCloud == true {
            defaults.setObject(1, forKey: "cloudOn")
        }else{
            defaults.setObject(0, forKey:"cloudOn")
        }
        
        defaults.synchronize()
        
        
        println("defaults \(defaults)")
        println("set icloud default to \(cloudOn)")
        
        let test = defaults.objectForKey("cloudOn") as! Int
        println("default stored \(test)")
        
    }
    
    
    
    
    
    
    
    
    @IBAction func removeDuplicates () {
        
        // get current status
        cloudOn = defaults.objectForKey("cloudOn") as! Int
        
        if cloudOn == 1 {
            stack.deDupCloud()
        }else{
            stack.deDupLocal()
        }
    }
    
    
    
    
    
    @IBAction func emailList() {
        
        //load db and grab records
        
        // get current status
        let defaults = NSUserDefaults.standardUserDefaults()
        var cloudOn:Bool!
        var moc: NSManagedObjectContext? = nil

        
        if let cloudOn = defaults.objectForKey("cloudOn") as? Bool {
            
            if cloudOn == true {
                moc = stack.cloudManagedObjectContext!
            }else{
                moc = stack.localManagedObjectContext!
            }
        }else{
            moc = stack.localManagedObjectContext!
        }

        
        let entity = NSEntityDescription.entityForName("Todo", inManagedObjectContext: moc!)
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        
        let listSort = NSSortDescriptor(key: "list", ascending: true)
        let todoSort = NSSortDescriptor(key: "name", ascending: true)
        
        fetchRequest.sortDescriptors = [listSort, todoSort]
        fetchRequest.returnsDistinctResults = true
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        
        let records = moc?.executeFetchRequest(fetchRequest, error: nil) as! [Todo]
        
        
        var dataString = "list, item, date, completed"
        var finished = false
        
        for todo in records {
            
            if let todoList = todo.list as TodoList?  {
                
                let dateString = dateFormatter.stringFromDate(todo.date)
                
                if todo.completed == 1 { finished = true }else{ finished = false }
                
                let newLine = ("\n \(todo.list.name), \(todo.name), \(dateString), \(finished) ")
                dataString += newLine
                
            }else{  // delete orphaned item
                
            }
        }
        
        
        // email the string
        let shareItem = [dataString]
        let activityController = UIActivityViewController(activityItems: shareItem, applicationActivities: nil)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            let os = (UIDevice.currentDevice().systemVersion as NSString).floatValue
            
            if os >= 8.0 {
                activityController.popoverPresentationController?.sourceView = shareView
            }
        }
        self.presentViewController(activityController, animated: true, completion: nil)
    }

    
    
    @IBAction func emailSupport(){
        
        var error: NSError? = nil
        
        
        let messageBody = "If after switching between iCloud and local: your lists don't appear, or changes aren't saved then close the app and restart it. \n\nDouble click the home button, scroll to AlphaList, swipe up.\n\nAny other problems, feature requests, comments let us know."
        
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients(["timestocome@gmail.com"])
        mailComposer.setMessageBody(messageBody, isHTML: false)
        
        
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            mailComposer.setSubject("Alpha List verion 8.1 iPad")
        }else{
            mailComposer.setSubject("Alpha List verion 8.1 iPhone")
        }

        presentViewController(mailComposer, animated: true, completion: nil)

        
    }
    

    
    @IBAction func emailDatabase(){
        
            var error: NSError
            
            mailComposer.mailComposeDelegate = self
            mailComposer.setSubject("Email local Database")
            mailComposer.setMessageBody("database and log file", isHTML: false)
            
            let fileDir = stack.applicationDocumentsDirectory
            let filePath = fileDir.URLByAppendingPathComponent("/ToDoList.sqlite")
            let database = NSData(contentsOfURL: filePath)
            
            mailComposer.addAttachmentData(database, mimeType: "application/x-sqlite3", fileName: "ToDoList.sqlite")
            
            
            let logFilePath = filePath.URLByAppendingPathComponent("/ToDoList-wal")
            let logFile = NSData(contentsOfURL: logFilePath)
            
            mailComposer.addAttachmentData(logFile, mimeType: "application/x-sqlite3", fileName: "ToDoList-wal")
        
        presentViewController(mailComposer, animated: true, completion: nil)
    }
   
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        
        println("mailComposeController didFinish")
        
        switch result.value {
        case MFMailComposeResultCancelled.value:
            println("Mail cancelled")
        case MFMailComposeResultSaved.value:
            println("Mail saved")
        case MFMailComposeResultSent.value:
            println("Mail sent")
        case MFMailComposeResultFailed.value:
            println("Mail sent failure: %@", [error.localizedDescription])
        default:
            break
        }
        
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    

    
    @IBAction func rate(){
    
        UIApplication.sharedApplication().openURL(NSURL(string: "itms-apps://itunes.apple.com/app/id328077994")!)
    }
    
    
    @IBAction func share() {
        
        // email the string
        
        let messageString = "Alpha List Link: itms-apps://itunes.apple.com/us/app/fit-test/id328077994?mt=8"

        let shareItem = [messageString]
        let activityController = UIActivityViewController(activityItems: shareItem, applicationActivities: nil)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            let os = (UIDevice.currentDevice().systemVersion as NSString).floatValue
            
            if os >= 8.0 {
                activityController.popoverPresentationController?.sourceView = shareView
            }
        }
        self.presentViewController(activityController, animated: true, completion: nil)
    }

    
}
