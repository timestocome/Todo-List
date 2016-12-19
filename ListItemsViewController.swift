//
//  ListItemsViewController.swift
//  GenericListWithSyncing
//
//  Created by Linda Cobb on 11/21/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import UIKit
import CoreData


// add email a list button




class ListItemsViewController: UITableViewController, NSFetchedResultsControllerDelegate, UITextFieldDelegate
{
    
    let stack = CoreDataStack()
    var managedObjectContext: NSManagedObjectContext? = nil
    var todoList:TodoList?
    
    // font colors
    let blue = UIColor(red: 0.0, green: 68.0/255.0, blue: 119.0/255.0, alpha: 1.0)
    let grey = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.8)
    
    // adjustable text
    var newRowHeight: CGFloat = 43.0
    
    
    // needed for inserting new items
    var editingRowIndexPath = NSIndexPath(forRow:0, inSection:0)
    let topRowIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    
    
    
    
    // need for ipad to email a list
    @IBOutlet weak var shareView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardWillShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        // font size notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "preferredContentSizeChanged:", name: UIContentSizeCategoryDidChangeNotification, object: nil)
        
        fetchedResultsController.delegate = self

        
        let backgroundView = UIImageView(frame: tableView.frame)
        let backgroundImage = UIImage(named: "paper.png")
        backgroundView.image = backgroundImage
        tableView.backgroundView = backgroundView
        tableView.backgroundView?.layer.zPosition = -1

    }
    
    
    override func viewDidAppear(animated: Bool) {
        setupRefreshControl()
        refreshControl?.endRefreshing()
       
    }
    
    
    
    func configureView() {
        
        
        if todoList == nil {
            println ("no todo list yet")
            title = "First select a list to add items to:"
        }else{
            let titleText = NSString(format: "%@ (%d)", todoList!.name, tableView.numberOfRowsInSection(0))
           // title = todoList?.name
            title = titleText as String
            
            
            let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
            let emailButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "emailList")
            self.navigationItem.rightBarButtonItems = [addButton, emailButton]
        }
    }
    
    
    func setupRefreshControl () {
        
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = blue
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull down and release to add a list")
        refreshControl?.addTarget(self, action: Selector("insertNewObject:"), forControlEvents: UIControlEvents.ValueChanged)
        
    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    
        return newRowHeight
    }
    

    
    
    func preferredContentSizeChanged (notification: NSNotification) {
        
        // get new rowHeight for fontSize
        var label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        label.text = "calc row height"
        label.sizeToFit()
        
        newRowHeight = label.frame.height * 1.7

        self.tableView.reloadData()
    }
    
    
    
    
    
    func insertNewObject(sender: AnyObject) {
        
        
        refreshControl?.endRefreshing()
        
        if todoList == nil { return }
        
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as! Todo
        
        newManagedObject.setValue(NSDate(), forKey: "date")
        newManagedObject.setValue(" ", forKey: "name")
        newManagedObject.setValue( false, forKey: "completed")
        newManagedObject.setValue(todoList, forKey: "list")
        
        todoList?.addTodo(newManagedObject)
        
        // Save the context and do something useful if the save fails
        var error: NSError? = nil
        if !context.save(&error) { println("insert new item fail \(error)") }
        
        // cell is created before object, so update the table cell text here
        let cell = tableView.cellForRowAtIndexPath(topRowIndexPath) as! TodoTableCell
        cell.todo = newManagedObject as Todo
        cell.textField?.becomeFirstResponder()
    
        let titleText = NSString(format: "%@ (%d)", todoList!.name, tableView.numberOfRowsInSection(0))
        // title = todoList?.name
        title = titleText as String

        
    }
    
    
    
    
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:TodoTableCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TodoTableCell
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Todo
        
        let todoCell = cell as! TodoTableCell
        let todo = object as Todo
        todoCell.todo = todo
        
        var textField = todoCell.viewWithTag(100) as! UITextField
        textField.text = object.valueForKey("name") as! NSString as String
        textField.textColor = blue
        textField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        textField.delegate = self

        
        if object.completed == true {
            todoCell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            todoCell.accessoryType = UITableViewCellAccessoryType.None
        }
       
    }
    
    
    
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {
            
            let deletedItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Todo
            deleteTodo(deletedItem)
        }
    }
    
    
 
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath ){
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Todo
        var finished = object.completed
        
        if finished == true {
            cell?.accessoryType = UITableViewCellAccessoryType.None
            object.completed = false
        }else{
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
            object.completed = true
            object.date = NSDate()
        }
        
        let context = self.fetchedResultsController.managedObjectContext
        var error: NSError? = nil
        if !context.save(&error) {}

    }
    
    
    
    func animateInsert() {

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
                        let cell = tableCell as! TodoTableCell
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
                        //  if tableCell as UITableViewCell == lastView {}
                })
            }
        }
        
    }
    
    
    func deleteTodo (deletedTodo: Todo) {
        
        let context = self.fetchedResultsController.managedObjectContext
        context.deleteObject(deletedTodo)
        deletedTodo.list.removeTodo(deletedTodo)
        var error: NSError? = nil
        if !context.save(&error) {}
        
        let titleText = NSString(format: "%@ (%d)", todoList!.name, tableView.numberOfRowsInSection(0))
        // title = todoList?.name
        title = titleText as String
        

    }
    
    
    // fade cells not being edited, and scroll if needed
    func textFieldDidBeginEditing(textField: UITextField) {

        
        let visibleCells = tableView.visibleCells()
        let animationTime = 0.2
        var delay = 0.0
        
        
        // fade color other cells
        for tableCell in visibleCells {
            
            let tableCell = tableCell as! TodoTableCell
            if tableCell.textField != textField  {
                
                let todoCell = tableCell as TodoTableCell
                todoCell.userInteractionEnabled = false
                
                UIView.animateWithDuration( animationTime,
                    delay: delay,
                    options: UIViewAnimationOptions.CurveEaseIn,
                    animations: {
                        let fadeCell = tableCell as TodoTableCell
                        fadeCell.textField!.textColor = self.grey
                        delay += animationTime
                    },
                    completion: {
                        (value bool) in
                })
            }else{  // get row number for edited item
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
        
        // save the edit
        var editedTodo = self.fetchedResultsController.objectAtIndexPath(editingRowIndexPath) as! Todo
        editedTodo.name = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        var error: NSError? = nil
        let context = self.fetchedResultsController.managedObjectContext
        if !context.save(&error) { println("failed to save edited item \(error)") }
        
        
        // unfade color
        let visibleCells = tableView.visibleCells()
        let animationTime = 0.2
        var delay = 0.0
        
        let count = CGFloat(visibleCells.count)
        let topRect = CGRectMake( 0, 0, 44, 320)
        
        
        for tableCell in visibleCells {
            
            let todoCell = tableCell as! TodoTableCell
            todoCell.userInteractionEnabled = true
            
            
            UIView.animateWithDuration( animationTime,
                delay: delay,
                options: UIViewAnimationOptions.CurveEaseIn,
                animations: {
                    let fadeCell = tableCell as! TodoTableCell
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
    
    
    
    
    
    var fetchedResultsController: NSFetchedResultsController {
        
        if _fetchedResultsController != nil { return _fetchedResultsController!  }
        
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Todo", inManagedObjectContext: managedObjectContext!)
        fetchRequest.entity = entity
        
        
    
        // just grab todos from current list
        var nameObject  = todoList?.name
        if nameObject != nil {
            let predicate = NSPredicate(format: "list.name=%@", nameObject!)
            fetchRequest.predicate = predicate
        }else{
            nameObject = "noList"
            let predicate = NSPredicate(format: "list.name=%@", nameObject!)
            fetchRequest.predicate = predicate
        }
        
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: "localizedCaseInsensitiveCompare:")
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        
        
        // do something useful if fetch fails
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) {}
        
        
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
    
    
    
    func emailList() {
                
        //collect the data and string it together
        let listItems = fetchedResultsController.fetchedObjects as! [Todo]
        var data = ""
        
        var todo:Todo
        var name:NSString
        var date:NSDate
        var formattedDate:NSString
        var completed:Bool
        var todoString = ""
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        
        for item in listItems {
            
            name = item.valueForKey("name") as! NSString
            date = item.valueForKey("date") as! NSDate
            formattedDate = dateFormatter.stringFromDate(date)
            completed = item.valueForKey("completed") as! Bool
            
            if completed == false {
                todoString = ("\n \(name), \(formattedDate)")
            }else{
                todoString = ("\n Completed \(name) \(formattedDate)")
            }
            
            data = data + todoString
        }
        
        // email the string
        let shareItem = [data]
        let activityController = UIActivityViewController(activityItems: shareItem, applicationActivities: nil)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            let os = (UIDevice.currentDevice().systemVersion as NSString).floatValue
            
            if os >= 8.0 {
                activityController.popoverPresentationController?.sourceView = shareView
            }
        }
        self.presentViewController(activityController, animated: true, completion: nil)
    }
    
    
       
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    




}