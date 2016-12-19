//
//  ToDoList.swift
//  GenericListWithSyncing
//
//  Created by Linda Cobb on 11/20/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import CoreData

class TodoList: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var timeStamp: NSDate
    @NSManaged var todo: NSMutableSet
    
    
    func addTodo(insertTodo: Todo) {  todo.addObject(insertTodo)  }
    func removeTodo(deleteTodo: Todo) {  todo.removeObject(deleteTodo)  }

}
