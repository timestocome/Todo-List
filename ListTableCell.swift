//
//  ListTableCell.swift
//  TableAnimations
//
//  Created by Linda Cobb on 11/17/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import UIKit



protocol ListTableCellDelegate {
    func todoListDeleted(listToDelete: TodoList)
}
    


class ListTableCell: UITableViewCell
{
 
    
    @IBOutlet var textField: UITextField?
    var todolist: TodoList!
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let backgroundView = UIImageView(frame: self.frame)
        let backgroundImage = UIImage(named: "tableRow.png")
        backgroundView.image = backgroundImage
        self.backgroundView = backgroundView
        self.backgroundView?.layer.zPosition = -1

    }
    
    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
      
    
}
