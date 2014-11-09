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

class ReminderTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate {

  
  var context : NSManagedObjectContext!
  var fetchController : NSFetchedResultsController!
  var line : MKPolyline!
  var dragCircle : UIView!
  var circle : MKCircle?
  var offset : (Double, Double)?
  var currentSelectedReminder : Reminder!
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var editButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    mapView.delegate = self
    setupDragCircle()
    setupGestureRecognizers()
    setupFetchController()

    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 48.0

  }
  
  func setupDragCircle() {
    
    dragCircle = UIView(frame: CGRect(origin: CGPoint(x: -20, y: -20), size: CGSize(width: 20, height: 20)))
    dragCircle.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.7)
    dragCircle.layer.cornerRadius = dragCircle.frame.height / 2
    dragCircle.clipsToBounds = true
    self.view.addSubview(dragCircle)
    
  }
  
  func setupFetchController() {
    
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
    
  }
  
  func setupGestureRecognizers() {
    
    let mapPanRecognizer = UIPanGestureRecognizer()
    mapPanRecognizer.addTarget(self, action: "didPan:")
    mapPanRecognizer.delegate = self
    mapView.addGestureRecognizer(mapPanRecognizer)
    
    let mapPinchRecognizer = UIPinchGestureRecognizer()
    mapPinchRecognizer.addTarget(self, action: "didPinch:")
    mapPinchRecognizer.delegate = self
    mapView.addGestureRecognizer(mapPinchRecognizer)
    
    let circlePanRecognizer = UIPanGestureRecognizer()
    circlePanRecognizer.addTarget(self, action: "didPanCircle:")
    dragCircle.addGestureRecognizer(circlePanRecognizer)
    
  }

  // MARK: - Table View Data Source

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
  
  // MARK : Table View Delegate
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
      if editingStyle == .Delete {
        context.deleteObject(fetchController.fetchedObjects![indexPath.row] as Reminder)
        var error : NSError?
        context.save(&error)}
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    mapView.removeOverlays(mapView.overlays)
    let reminder = fetchController.fetchedObjects![indexPath.row] as Reminder
    currentSelectedReminder = reminder
    circle = MKCircle(centerCoordinate: CLLocationCoordinate2DMake(CLLocationDegrees(reminder.latitude), CLLocationDegrees(reminder.longitude)), radius: CLLocationDistance(reminder.radius))
    mapView.addOverlay(circle)
    
    mapView.setVisibleMapRect(circle!.boundingMapRect, edgePadding: UIEdgeInsetsMake(20, 20, 20, 20), animated: true)

    let lat1 = circle!.coordinate.latitude
    let long1 = circle!.coordinate.longitude
    let lat2 = circle!.coordinate.latitude
    let long2 = circle!.coordinate.longitude + CLLocationDegrees(Double(reminder.radius) * 0.000013)
    
    circle?.boundingMapRect.size
    
    var coordinatesForLine = [CLLocationCoordinate2D(latitude: lat2, longitude: long2), circle!.coordinate]
    
    line = MKPolyline(coordinates: &coordinatesForLine, count: coordinatesForLine.count)
    
    offset = (lat2 - circle!.coordinate.latitude, long2 - circle!.coordinate.longitude)
    println(offset)
    
    mapView.addOverlay(line)
    
    placeDragCircle()
    
  }
  
  // MARK: - Map View Delegate
  
  func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
    if overlay === line {
      
      let renderer = MKPolylineRenderer(overlay: overlay)
      renderer.strokeColor = UIColor.blackColor()
      renderer.lineWidth = 1
      renderer.lineDashPattern = [2,2]
      return renderer
      
    } else {
      
      let renderer = MKCircleRenderer(overlay: overlay)
      renderer.fillColor = UIColor.greenColor().colorWithAlphaComponent(0.2)
      renderer.lineWidth = 2
      renderer.strokeColor = UIColor.greenColor()
      
      return renderer
    }
  }
  
  func mapViewDidFinishRenderingMap(mapView: MKMapView!, fullyRendered: Bool) {
    placeDragCircle()
  }
  
  // MARK: - Fetch Controller Delegate

  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    
    switch type {
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
    case .Insert:
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
    default:
      println("Doing nothing!")
    }
  }
  
  // MARK: - Gesture Recognizers
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  func didPinch(sender: UIPinchGestureRecognizer){
    placeDragCircle()
  }
  
  func didPan(sender: UIPanGestureRecognizer){
    placeDragCircle()
  }
  
  func didPanCircle(sender: UIPanGestureRecognizer){
    let point = sender.locationInView(self.view)
    dragCircle.center = point
    
    let coord = mapView.convertPoint(point, toCoordinateFromView: self.view)
    let lat1 = circle!.coordinate.latitude
    let long1 = circle!.coordinate.longitude
    let lat2 = coord.latitude
    let long2 = coord.longitude
    
    if sender.state == UIGestureRecognizerState.Changed {

      mapView.removeOverlay(circle)
      mapView.removeOverlay(line)
      circle = MKCircle(centerCoordinate: circle!.coordinate, radius: CLLocation(latitude: lat1, longitude: long1).distanceFromLocation(CLLocation(latitude: lat2, longitude: long2)))
      mapView.addOverlay(circle)
      
      var coordinatesForLine = [CLLocationCoordinate2D(latitude: lat2, longitude: long2), circle!.coordinate]
      
      line = MKPolyline(coordinates: &coordinatesForLine, count: coordinatesForLine.count)
      offset = (lat2 - circle!.coordinate.latitude, long2 - circle!.coordinate.longitude)
      println(offset)
      
      mapView.addOverlay(line)
    }
    
    if sender.state == UIGestureRecognizerState.Ended {
      currentSelectedReminder.radius = CLLocation(latitude: lat1, longitude: long1).distanceFromLocation(CLLocation(latitude: lat2, longitude: long2))
      var error: NSError?
      context.save(&error)
    }
  }
  
  // MARK: - Other
  
  func placeDragCircle(){
    if circle != nil {
      let point = CLLocationCoordinate2D(latitude: Double(circle!.coordinate.latitude) + offset!.0, longitude: Double(circle!.coordinate.longitude + offset!.1))
      dragCircle!.center = mapView.convertCoordinate(point, toPointToView: self.mapView)
      println(dragCircle!.center)

    }
  }
  
  func didGetCloudChanges(notification : NSNotification) {
    self.context.mergeChangesFromContextDidSaveNotification(notification)
  }

  @IBAction func editButtonPressed() {
    
    tableView.setEditing(!tableView.editing, animated: true)
    if !tableView.editing {
      editButton.titleLabel!.text = "Edit"
    } else {
      editButton.titleLabel!.text = "Done"
    }
  }
  
}
