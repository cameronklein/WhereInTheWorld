//
//  AddReminderViewController.swift
//  Where In The World?
//
//  Created by Cameron Klein on 11/4/14.
//  Copyright (c) 2014 Cameron Klein. All rights reserved.
//

import UIKit

class AddReminderViewController: UIViewController {

  @IBOutlet weak var topLabel: UILabel!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var spinningWheel: UIActivityIndicatorView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "dismissWithSaveNotification", name: "dismissWithSaveNotification", object: nil)

    // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
    
  @IBAction func cancelButtonPressed(sender: AnyObject) {
    NSNotificationCenter.defaultCenter().postNotificationName("cancelPressed", object: self, userInfo: nil)
    dismiss()
  }

  @IBAction func confirmButtonPressed(sender: AnyObject) {
    NSNotificationCenter.defaultCenter().postNotificationName("addReminder", object: self, userInfo: nil)
  }
  
  func dismiss(){
    UIView.animateWithDuration(0.4,
      delay: 0.0,
      options: UIViewAnimationOptions.CurveEaseInOut,
      animations: { () -> Void in
        self.view.frame.origin.y += 125
      },
      completion: { (success) -> Void in
        self.confirmButton.alpha = 1
        self.cancelButton.alpha = 1
        self.topLabel.alpha = 1
        self.spinningWheel.alpha = 1
        self.topLabel.text = "Adjust radius and press button to confirm."
    })
    
  }
  
  func dismissWithSaveNotification(){
    spinningWheel.startAnimating()
    
    UIView.animateWithDuration(0.4,
      delay: 0.0,
      options: UIViewAnimationOptions.CurveEaseInOut,
      animations: { () -> Void in
        self.confirmButton.alpha = 0
        self.cancelButton.alpha = 0
        self.topLabel.alpha = 0
      }) { (success) -> Void in
        self.topLabel.text = "Saved!"
        UIView.animateWithDuration(0.4,
          delay: 1.0,
          options: UIViewAnimationOptions.CurveEaseInOut,
          animations: { () -> Void in
            self.spinningWheel.alpha = 0
            self.topLabel.alpha = 1
          },
          completion: { (success) -> Void in
            NSThread.sleepForTimeInterval(0.4)
            self.spinningWheel.stopAnimating()
            self.dismiss()
        })
    }
    
  }

}
