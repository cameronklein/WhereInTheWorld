//
//  Reminder Cell.swift
//  Where In The World?
//
//  Created by Cameron Klein on 11/7/14.
//  Copyright (c) 2014 Cameron Klein. All rights reserved.
//

import UIKit

class ReminderCell: UITableViewCell {
  
  @IBOutlet weak var onOff: UISwitch!
  @IBOutlet weak var reminderNameLabel: UILabel!
  var reminder : Reminder!
  
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

  override func setSelected(selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)

      // Configure the view for the selected state
  }
  
  
  @IBAction func switchedSwitch(sender: UISwitch) {
    if sender.on {
      let dict : [NSObject : AnyObject] = ["reminder" : reminder]
      NSNotificationCenter.defaultCenter().postNotificationName("reactivateRegion", object: nil, userInfo: dict)
      reminder.isOn = true
      let appDel = UIApplication.sharedApplication().delegate as AppDelegate
      appDel.saveContext()
      
    } else {
    
      println("Switched switch!!!")
      let dict : [NSObject : AnyObject] = ["id" : reminder.locationID]
      NSNotificationCenter.defaultCenter().postNotificationName("removeRegion", object: nil, userInfo: dict)
      reminder.isOn = false
      let appDel = UIApplication.sharedApplication().delegate as AppDelegate
      appDel.saveContext()
    }
  }
  
}
