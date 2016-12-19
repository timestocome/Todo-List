//
//  TodoTableCell.swift
//  GenericListWithSyncing
//
//  Created by Linda Cobb on 11/21/14.
//  Copyright (c) 2014 TimesToCome Mobile. All rights reserved.
//

import Foundation
import UIKit

class TodoTableCell: UITableViewCell, UITextFieldDelegate
{

    
    @IBOutlet var textField: UITextField?
    
    var todo: Todo!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textField?.delegate = self
        
        
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
