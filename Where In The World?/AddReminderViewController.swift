//
//  AddReminderViewController.swift
//  Where In The World?
//
//  Created by Cameron Klein on 11/4/14.
//  Copyright (c) 2014 Cameron Klein. All rights reserved.
//

import UIKit

class AddReminderViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
    
  @IBAction func cancelButtonPressed(sender: AnyObject) {
    dismiss()
  }

  @IBAction func confirmButtonPressed(sender: AnyObject) {
    //NSNotificationCenter.defaultCenter().postNotificationName("reminderAdded", object: self, userInfo: <#[NSObject : AnyObject]?#>)
  }
  
  func dismiss(){
    UIView.animateWithDuration(0.4,
      delay: 0.0,
      options: UIViewAnimationOptions.CurveEaseInOut,
      animations: { () -> Void in
        self.view.frame.origin.y += 125
      },
      completion: nil)
  }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
