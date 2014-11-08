//
//  ReminderTableViewController.swift
//  Where In The World?
//
//  Created by Cameron Klein on 11/5/14.
//  Copyright (c) 2014 Cameron Klein. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class ReminderTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, MKMapViewDelegate {

  
  var context : NSManagedObjectContext!
  var fetchController : NSFetchedResultsController!
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var mapView: MKMapView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    mapView.delegate = self
    
    let appDel = UIApplication.sharedApplication().delegate as AppDelegate
    context = appDel.managedObjectContext
    
    var fetchRequest = NSFetchRequest(entityName: "Reminder")
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
    self.fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "Reminders")
    fetchController.delegate = self
    
    var error : NSError?
    fetchController.performFetch(&error)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "didGetCloudChanges:", name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: appDel.persistentStoreCoordinator)
    
    if error != true {
      println(error?.localizedDescription)
    }
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 48.0

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }

  // MARK: - Table view data source

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.fetchController.fetchedObjects!.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("REMINDER_CELL", forIndexPath: indexPath) as ReminderCell
    let reminder = self.fetchController.fetchedObjects![indexPath.row] as Reminder
    cell.reminderNameLabel.text = reminder.name
    cell.reminder = reminder
    cell.onOff.on = reminder.isOn
    
    return cell
  }
  

  /*
  // Override to support conditional editing of the table view.
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
      // Return NO if you do not want the specified item to be editable.
      return true
  }
  */


  /*
  // Override to support editing the table view.
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
      if editingStyle == .Delete {
          // Delete the row from the data source
          tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      } else if editingStyle == .Insert {
          // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
      }    
  }
  */

  /*
  // Override to support rearranging the table view.
  override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

  }
  */

  /*
  // Override to support conditional rearranging of the table view.
  override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
      // Return NO if you do not want the item to be re-orderable.
      return true
  }
  */

  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      // Get the new view controller using [segue destinationViewController].
      // Pass the selected object to the new view controller.
  }
  */
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    mapView.removeOverlays(mapView.overlays)
    let reminder = fetchController.fetchedObjects![indexPath.row] as Reminder
    let circle = MKCircle(centerCoordinate: CLLocationCoordinate2DMake(CLLocationDegrees(reminder.latitude), CLLocationDegrees(reminder.longitude)), radius: CLLocationDistance(reminder.radius))
    mapView.addOverlay(circle)
    
    mapView.setVisibleMapRect(circle.boundingMapRect, edgePadding: UIEdgeInsetsMake(20, 20, 20, 20), animated: true)
    
  }
  
  func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
    let renderer = MKCircleRenderer(overlay: overlay)
    renderer.fillColor = UIColor.greenColor().colorWithAlphaComponent(0.2)
    renderer.lineWidth = 2
    renderer.strokeColor = UIColor.greenColor()
    
    return renderer
  }
  
  func didGetCloudChanges(notification : NSNotification) {
    self.context.mergeChangesFromContextDidSaveNotification(notification)
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    self.tableView.reloadData()
  }
  
  

}
