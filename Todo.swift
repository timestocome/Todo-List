//
//  ToDo.swift
//  GenericListWithSyncing
//
//  Created by Linda Cobb on 11/20/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import CoreData

class Todo: NSManagedObject {

    @NSManaged var completed: NSNumber
    @NSManaged var date: NSDate
    @NSManaged var name: String
    @NSManaged var list: TodoList

}
