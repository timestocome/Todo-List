//
//  MasterViewController.swift
//  GenericListWithSyncing
//
//  Created by Linda Cobb on 11/20/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import UIKit
import CoreData






class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, UITextFieldDelegate, ListTableCellDelegate
{

    
    var detailViewController: ListItemsViewController? = nil
    
    // db stuff
    var managedObjectContext: NSManagedObjectContext? = nil
    var persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil
    var stack: CoreDataStack = CoreDataStack()
    var cloudOn = 0
    

    // font colors
    let blue = UIColor(red: 0.0, green: 68.0/255.0, blue: 119.0/255.0, alpha: 1.0)
    let grey = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.8)
    
    // adjustable text
    var newRowHeight:CGFloat = 43.0
    
    
    // needed for inserting new items
    var editingRowIndexPath = NSIndexPath(forRow:0, inSection:0)
    let topRowIndexPath = NSIndexPath(forRow: 0, inSection: 0)


    
    
    override func awakeFromNib() {
        
        // get current status
        loadCloudOrLocalDatabase()
        
        
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
        
        
        
        let backgroundView = UIImageView(frame: tableView.frame)
        let backgroundImage = UIImage(named: "paper.png")
        backgroundView.image = backgroundImage
        tableView.backgroundView = backgroundView
        tableView.backgroundView?.layer.zPosition = -1
    }

    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        // keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardWillShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        // font size notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "preferredContentSizeChanged:", name: UIContentSizeCategoryDidChangeNotification, object: nil)

        // iCloud notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "iCloudNotificationArrived:",
            name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: nil)
        
        // store change notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "storeChanged:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: nil)

        
        fetchedResultsController.delegate = self
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? ListItemsViewController
            self.detailViewController?.managedObjectContext = managedObjectContext
        }
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        // get current status
        loadCloudOrLocalDatabase()
        
        
        super.awakeFromNib()
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    
       
    override func viewDidAppear(animated: Bool) {
    
        var current =  managedObjectContext?.persistentStoreCoordinator?.persistentStores[0] as! NSPersistentStore
        var location = current.URL
        tableView.reloadData()
        
        setupRefreshControl()
        refreshControl?.endRefreshing()
        
    }
    
    
    override func viewDidDisappear(animated: Bool) {
    
        var error:NSError? = nil
        managedObjectContext?.save(&error)
        
        refreshControl = nil
    }
    
    
    func setupRefreshControl () {
        
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = blue
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull down and release to add a list")
        refreshControl?.addTarget(self, action: Selector("insertNewObject:"), forControlEvents: UIControlEvents.ValueChanged)
    }
    
    
    func preferredContentSizeChanged (notification: NSNotification) {
        
        // get new rowHeight for fontSize
        var label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        label.text = "calc row height"
        label.sizeToFit()

        newRowHeight = label.frame.height * 1.7

        tableView.reloadData()
    }
    
    
    
    func storeChanged(notification: NSNotification){
      //  forceFetch()
      //  tableView.reloadData()
    }
    
   
    func iCloudNotificationArrived (notification: NSNotification ){
        
        var error: NSError? = nil
        
        if managedObjectContext?.hasChanges != nil  {
            managedObjectContext?.save(&error)
            println("\n\n\n save error ? \(error), \(error?.userInfo)\n\n\n")
        }
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("TodoList", inManagedObjectContext: managedObjectContext!)
        fetchRequest.entity = entity
        
        
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: "localizedCaseInsensitiveCompare:")
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        
        
        // do something useful if fetch fails
        if !_fetchedResultsController!.performFetch(&error) { println("FetchedResultsFail: \(error)") }
        
        tableView.reloadData()
    }
    

    
    
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return newRowHeight;
    }
    

    func insertNewObject(sender: AnyObject) {
        
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as! NSManagedObject
             
        newManagedObject.setValue(NSDate(), forKey: "timeStamp")
        newManagedObject.setValue(" ", forKey: "name")
        
        
        // Save the context and do something useful if the save fails
        var error: NSError? = nil
        if !context.save(&error) { println("problem saving new object: \(error)") }
        
        // cell is created before object, so update the table cell text here
        let cell = tableView.cellForRowAtIndexPath(topRowIndexPath) as! ListTableCell
        cell.todolist = newManagedObject as! TodoList
        cell.textField?.becomeFirstResponder()
    }
    
    
    


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDetail" {
            
            if let indexPath = self.tableView.indexPathForSelectedRow() {
            
                let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! TodoList
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ListItemsViewController
                
                
                controller.todoList = object
                controller.managedObjectContext = self.fetchedResultsController.managedObjectContext
                
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
                
                controller.configureView()
            }
        }
    }
    
    
   
    

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:ListTableCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ListTableCell
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }

    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! TodoList
        
        let toDoListCell = cell as! ListTableCell
        let todoList = object as TodoList
        toDoListCell.todolist = todoList
        
        
        var textField = toDoListCell.viewWithTag(100) as! UITextField
        textField.text = object.valueForKey("name") as! String
        textField.textColor = blue
        textField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        textField.delegate = self

    }
    
    
    
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            todoListDeleted(fetchedResultsController.objectAtIndexPath(indexPath) as! TodoList)
        
        }
    }

    
    
    
    // make user pause and think before removing a list
    func todoListDeleted(listToDelete: TodoList){
        
        var alert = UIAlertController(title: "Deleting list",
            message: "This will delete all items on the list",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        
        
        alert.addAction(UIAlertAction(title: "Remove list",
                style: UIAlertActionStyle.Destructive,
            handler: {
                action in
                let context = self.fetchedResultsController.managedObjectContext
                
                context.deleteObject(listToDelete)
                
                // do something useful if save fails
                 var error: NSError? = nil
                 if !context.save(&error) {}

                
        }))
        
        alert.addAction(UIAlertAction(title: "Keep List",
            style: UIAlertActionStyle.Cancel,
            handler: {
                action in
                self.tableView.reloadData()
        }))
       
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
   
    
    
    
    

    
    func animateInsert() {
        
        self.refreshControl?.endRefreshing()
        
        var delay = 0.0
        let animationTime = 0.2
        let visibleCells = tableView.visibleCells()
        
        if visibleCells.count > 0 {
            let lastView = visibleCells.last as! UITableViewCell
            
            // animate each cell
            for tableCell in visibleCells {
                
                UIView.animateWithDuration(animationTime,
                    delay: delay,
                    options: UIViewAnimationOptions.CurveEaseIn,
                    animations: {
                        let cell = tableCell as! ListTableCell
                        cell.frame = CGRectOffset(cell.frame, 0.0, cell.frame.size.height)
                        delay += animationTime },
                    completion: {
                        (value Bool) in
                })
            }
        }
    }
    
    
    
    
    func animateDelete(deletedCell: UITableViewCell) {

        var delay = 0.0
        let animationTime = 0.2
        let visibleCells = tableView.visibleCells()
        let lastView = visibleCells.last as! UITableViewCell
        var startAnimating = false
        
        

        // animate each cell
        for tableCell in visibleCells {
            
            if tableCell as! UITableViewCell == deletedCell {
                startAnimating = true
            }
            
            if startAnimating == true {
                
                UIView.animateWithDuration(animationTime,
                    delay: delay,
                    options: UIViewAnimationOptions.CurveEaseIn,
                    animations: {
                        let cell = tableCell as! UITableViewCell
                        cell.frame = CGRectOffset(cell.frame, 0.0, -cell.frame.size.height)
                        delay += animationTime },
                    completion: {
                        (value Bool) in
                        self.refreshControl?.endRefreshing()
                        self.tableView.scrollToRowAtIndexPath(self.topRowIndexPath, atScrollPosition: .Top, animated: true)
                })
            }
        }
    

    }
    
    
    
    // fade cells not being edited, and scroll if needed
    func textFieldDidBeginEditing(textField: UITextField) {
        
        let visibleCells = tableView.visibleCells()
        let animationTime = 0.2
        var delay = 0.0
        
        
        // fade color other cells
        for tableCell in visibleCells {
            
            let tableCell = tableCell as! ListTableCell
            if tableCell.textField != textField {

                let listCell = tableCell as ListTableCell
                listCell.userInteractionEnabled = false
                
                UIView.animateWithDuration( animationTime,
                    delay: delay,
                    options: UIViewAnimationOptions.CurveEaseIn,
                    animations: {
                        let fadeCell = tableCell as ListTableCell
                        fadeCell.textField!.textColor = self.grey
                        delay += animationTime
                    },
                    completion: {
                        (value bool) in
                })
            }else{  // cell being edited, grab the row number
                editingRowIndexPath = tableView.indexPathForCell(tableCell)
            }
        }
    }
    
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    // fade cells back in and scroll
    func textFieldDidEndEditing(textField: UITextField) {
        
        // save edited object
        var editedTodoList = self.fetchedResultsController.objectAtIndexPath(editingRowIndexPath) as! TodoList
        editedTodoList.name = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        var error: NSError? = nil
        let context = self.fetchedResultsController.managedObjectContext
        if !context.save(&error) {}
        
        
        // unfade color
        let visibleCells = tableView.visibleCells()
        let animationTime = 0.2
        var delay = 0.0
        
        let count = CGFloat(visibleCells.count)
        let topRect = CGRectMake( 0, 0, 44, 320)
        
        
        for tableCell in visibleCells {
            
            let listCell = tableCell as! ListTableCell
            listCell.userInteractionEnabled = true
            
            
            UIView.animateWithDuration( animationTime,
                delay: delay,
                options: UIViewAnimationOptions.CurveEaseIn,
                animations: {
                    let fadeCell = tableCell as! ListTableCell
                    fadeCell.textField!.textColor = self.blue
                    delay += animationTime
                },
                completion: {
                    (value bool) in
            })
        }
        tableView.reloadData()
        tableView.scrollsToTop = true
    }
    
    
    
    func keyboardWasShown(notification: NSNotification){
        
        var info: NSDictionary = notification.userInfo!
        
    
        // resize table view to be above the keyboard
        if let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            
            let newHeight = tableView.frame.size.height - keyboardSize.size.height
            tableView.frame.size.height = newHeight
        }
        
    }
    
    
    
    
    func keyboardWillHide (notification: NSNotification){
        
        // resize tableview back to full screen
        let newHeight = UIScreen.mainScreen().bounds.height
        tableView.frame.size.height = newHeight
    }
    
    
    func keyboardWillChangeFrame(notification: NSNotification){}
    
    
    
    
    func loadCloudOrLocalDatabase() {
        
        // get current status
        let defaults = NSUserDefaults.standardUserDefaults()
        var cloudOn = 0
        
        if let testNil = defaults.objectForKey("cloudOn") as? Int {
        }else{      // nil value
            cloudOn = 0
            defaults.setObject(0, forKey: "cloudOn")
            defaults.synchronize()
        }
        
        cloudOn = defaults.objectForKey("cloudOn") as! Int
        
        if cloudOn == 1 {
                managedObjectContext = stack.cloudManagedObjectContext!
        }else{
                managedObjectContext = stack.localManagedObjectContext!
        }
        
        
        
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("TodoList", inManagedObjectContext: managedObjectContext!)
        fetchRequest.entity = entity
        
        
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: "localizedCaseInsensitiveCompare:")
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        
        
        // do something useful if fetch fails
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) { println("FetchedResultsFail: \(error)") }
        

        
        
    }
    
    
    
    var fetchedResultsController: NSFetchedResultsController {
        
        
        if _fetchedResultsController != nil { return _fetchedResultsController! }
        
        loadCloudOrLocalDatabase()
    
        
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("TodoList", inManagedObjectContext: managedObjectContext!)
        fetchRequest.entity = entity
        
        
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: "localizedCaseInsensitiveCompare:")
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        
        
        // do something useful if fetch fails
    	var error: NSError? = nil
    	if !_fetchedResultsController!.performFetch(&error) { println("FetchedResultsFail: \(error)") }
        
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    

    
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            case .Insert:
                animateInsert()
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            
            case .Delete:
                let cell = tableView.cellForRowAtIndexPath(indexPath!)
                animateDelete(cell!)
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            
            case .Update:
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
            
            default:
                return
        }
    }

    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

}

