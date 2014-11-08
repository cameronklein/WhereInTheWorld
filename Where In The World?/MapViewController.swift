//
//  ViewController.swift
//  Where In The World?
//
//  Created by Cameron Klein on 11/4/14.
//  Copyright (c) 2014 Cameron Klein. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
  
  let locationManager = CLLocationManager()
  var adjustableCircle : MKCircle?
  var dragCirclePoint: MKCircle?
  var dragCircle : UIView!
  var offset : (Double, Double)?
  var line : MKPolyline!
  var fetchController : NSFetchedResultsController!
  var context : NSManagedObjectContext!
  
  var annotationCenter : CLLocationCoordinate2D?
  var addVC : AddReminderViewController!
  let backgroundQueue = NSOperationQueue()
  
  @IBOutlet weak var mapView: MKMapView!
  
  // MARK: - Lifecycle Methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    checkLocationAuthorizationStatus()
    registerForNotifications()

    let appDel = UIApplication.sharedApplication().delegate as AppDelegate
    context = appDel.managedObjectContext
    
    self.mapView.delegate = self
    locationManager.delegate = self
  
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    setupDragCircle()
    setupGestureRecognizers()
    setupAddReminderViewController()
    loadOverlays()
    
  }
  
  //MARK: - MKMapViewDelegate
  
  func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
    
    if annotation.isKindOfClass(MKUserLocation){
      return nil
    }
    
    let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "ANNOTATION")
    annotationView.animatesDrop = true
    annotationView.canShowCallout = true
    
    let button = UIButton.buttonWithType(UIButtonType.ContactAdd) as UIButton
    annotationView.rightCalloutAccessoryView = button
    
    return annotationView
    
  }
  
  func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
    
    annotationCenter = view.annotation.coordinate
    mapView.selectAnnotation(nil, animated: true)
    mapView.removeOverlay(adjustableCircle)
    
    let regionSpan = mapView.region.span.longitudeDelta / 4
    let secondPointLatitude = view.annotation.coordinate.latitude
    let secondPointLongitude = view.annotation.coordinate.longitude + regionSpan
    let secondPoint = CLLocation(latitude: secondPointLatitude, longitude: secondPointLongitude)
    let center = CLLocation(latitude: view.annotation.coordinate.latitude, longitude: view.annotation.coordinate.longitude)
    let radius = center.distanceFromLocation(secondPoint)
    
    offset = (secondPointLatitude - center.coordinate.latitude, secondPointLongitude - center.coordinate.longitude)
    println(offset)
    
    adjustableCircle = MKCircle(centerCoordinate: view.annotation.coordinate, radius: radius)
    mapView.addOverlay(adjustableCircle)
    
    var coordinatesForLine = [CLLocationCoordinate2D(latitude: secondPoint.coordinate.latitude, longitude: secondPoint.coordinate.longitude), view.annotation.coordinate]

    line = MKPolyline(coordinates: &coordinatesForLine, count: coordinatesForLine.count)

    mapView.addOverlay(adjustableCircle)
    mapView.addOverlay(line)

    placeDragCircle()
    showAddViewController()
    
  }
  
  func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
    
    if overlay === line {
      
      let renderer = MKPolylineRenderer(overlay: overlay)
      renderer.strokeColor = UIColor.blackColor()
      renderer.lineWidth = 1
      renderer.lineDashPattern = [2,2]
      return renderer
      
    } else {
    
      var renderer = MKCircleRenderer(overlay: overlay)
      renderer.lineWidth = 2

      if overlay === adjustableCircle {
        renderer.fillColor = UIColor.blueColor().colorWithAlphaComponent(0.2)
        renderer.strokeColor = UIColor.blueColor()
        return renderer
      }
      
      for item in locationManager.monitoredRegions{
        let region = item as CLCircularRegion
        if (region.center.latitude == overlay.coordinate.latitude) && (region.center.longitude == overlay.coordinate.longitude){
          renderer.fillColor = UIColor.greenColor().colorWithAlphaComponent(0.2)
          renderer.strokeColor = UIColor.greenColor()
          return renderer
        }
      }
      renderer.fillColor = UIColor.redColor().colorWithAlphaComponent(0.1)
      renderer.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.4)
      return renderer
    }
  }
  
  
  func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
    mapView.removeOverlay(adjustableCircle)
    mapView.removeOverlay(line)
    dragCircle.frame.origin = CGPoint(x: -20, y: -20)
    for view in views {
      let thisView = view.annotation as MKAnnotation
      if !thisView.isKindOfClass(MKUserLocation){
        backgroundQueue.addOperationWithBlock({ () -> Void in
          NSThread.sleepForTimeInterval(0.4)
          NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            mapView.selectAnnotation(thisView, animated: true)
          })
        })
      }
    }
  }
  
  func mapView(mapView: MKMapView!, regionWillChangeAnimated animated: Bool) {
    placeDragCircle()
  }
  
  // MARK: - CLLocationManagerDelegate
  
  func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
    
    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
      var notification = UILocalNotification()
      notification.alertAction = "You made it!"
      notification.alertBody = "You made it!"
      notification.fireDate = NSDate()
      UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    println("Entered Region!")
  }
  
  // MARK: - Gesture Recognizers
  
  func setupGestureRecognizers() {
    
    let longPressRecognizer = UILongPressGestureRecognizer()
    longPressRecognizer.addTarget(self, action: "didPressLongingly:")
    mapView.addGestureRecognizer(longPressRecognizer)
    
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
  
  func didPressLongingly(sender: UILongPressGestureRecognizer) {
    
    if sender.state == .Began {
      let touchedAt = sender.locationInView(mapView)
      let touchCoord = self.mapView.convertPoint(touchedAt, toCoordinateFromView: self.mapView)
      
      self.mapView.removeAnnotations(self.mapView.annotations)
      
      var annotation =  MKPointAnnotation()
      annotation.coordinate = touchCoord
      annotation.title = "Add Reminder"
      
      self.mapView.addAnnotation(annotation)
      
    }
  }

  func didPinch(sender: UIPinchGestureRecognizer){
    placeDragCircle()
  }
  
  func didPan(sender: UIPanGestureRecognizer){
    placeDragCircle()
  }
  
  func didPanCircle(sender: UIPanGestureRecognizer){
    if sender.state == UIGestureRecognizerState.Changed {
      let point = sender.locationInView(self.view)
      dragCircle.center = point
      
      let coord = mapView.convertPoint(point, toCoordinateFromView: self.view)
      let lat1 = annotationCenter?.latitude
      let long1 = annotationCenter?.longitude
      let lat2 = coord.latitude
      let long2 = coord.longitude
      annotationCenter?.longitude
      
      mapView.removeOverlay(adjustableCircle)
      mapView.removeOverlay(line)
      adjustableCircle = MKCircle(centerCoordinate: annotationCenter!, radius: CLLocation(latitude: lat1!, longitude: long1!).distanceFromLocation(CLLocation(latitude: lat2, longitude: long2)))
      mapView.addOverlay(adjustableCircle)
      
      var coordinatesForLine = [CLLocationCoordinate2D(latitude: lat2, longitude: long2), annotationCenter!]
      
      
      line = MKPolyline(coordinates: &coordinatesForLine, count: coordinatesForLine.count)
      
      mapView.addOverlay(line)
    }
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

  // MARK: - Helper Methods
  
  func registerForNotifications(){
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reactivateRegion:", name: "reactivateRegion", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "cancelPressed", name: "cancelPressed", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "removeRegion:", name: "removeRegion", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "addReminder", name: "addReminder", object: nil)
    
  }
  
  func checkLocationAuthorizationStatus() {
    
    switch CLLocationManager.authorizationStatus() {
    case .Authorized:
      println("Authorized")
      locationManager.startUpdatingLocation()
      self.mapView.showsUserLocation = true
    case .NotDetermined:
      println("Not Determined")
      self.locationManager.requestAlwaysAuthorization()
    case .Restricted:
      println("Restricted")
    case .Denied:
      println("Denied")
    case .AuthorizedWhenInUse:
      println("Authorized When In Use")
    }

  }
  
  func setupDragCircle() {
    
    dragCircle = UIView(frame: CGRect(origin: CGPoint(x: -20, y: -20), size: CGSize(width: 20, height: 20)))
    dragCircle.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.7)
    dragCircle.layer.cornerRadius = dragCircle.frame.height / 2
    dragCircle.clipsToBounds = true
    self.view.addSubview(dragCircle)
    
  }
  
  func setupAddReminderViewController() {
    
    addVC = AddReminderViewController(nibName:"AddReminderViewController", bundle: NSBundle.mainBundle())
    self.addChildViewController(addVC)
    let screenHeight = self.view.frame.height
    let screenWidgth = self.view.frame.width
    addVC.view.frame = CGRect(origin: CGPoint(x: 0, y: screenHeight), size: CGSize(width: screenWidgth, height: 125.0))
    self.view.addSubview(addVC.view)
    
  }
  
  func placeDragCircle(){
    if adjustableCircle != nil {
      let point = CLLocationCoordinate2D(latitude: Double(adjustableCircle!.coordinate.latitude) + offset!.0, longitude: Double(adjustableCircle!.coordinate.longitude + offset!.1))
      dragCircle!.center = mapView.convertCoordinate(point, toPointToView: self.mapView)
      println(dragCircle!.center)
    }
  }
  
  func cancelPressed() {
    dragCircle.frame = CGRect(origin: CGPoint(x: -15, y: -15), size: CGSize(width: 15, height: 15))
    mapView.removeOverlay(adjustableCircle)
    mapView.removeAnnotations(mapView.annotations)
  }
  
  func addReminder() {

    println("Add Reminder Called")
    let alert = UIAlertController(title: nil, message: "Name your reminder", preferredStyle: .Alert)
    let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
      
      let appDel = UIApplication.sharedApplication().delegate as AppDelegate
      let context = appDel.managedObjectContext
      let reminder = NSEntityDescription.insertNewObjectForEntityForName("Reminder", inManagedObjectContext: context!) as Reminder
      
      reminder.setValue(self.annotationCenter?.longitude, forKey: "longitude")
      reminder.setValue(self.annotationCenter?.latitude, forKey: "latitude")
      reminder.setValue(self.adjustableCircle?.radius, forKey: "radius")
      reminder.setValue(true, forKey: "isOn")
      reminder.setValue(NSDate(), forKey: "createdAt")
      reminder.setValue(NSDate(), forKey: "lastSwitched")
      let id = arc4random_uniform(UInt32(100000)).description
      reminder.setValue(id, forKey: "locationID")
      let textField = alert.textFields!.first! as UITextField
      reminder.setValue(textField.text, forKey: "name")
      var error : NSError?
      context?.save(&error)
      if error != nil {
        println(error?.localizedDescription)
      }
      
      NSNotificationCenter.defaultCenter().postNotificationName("dismissWithSaveNotification", object: nil)
      self.mapView.removeAnnotations(self.mapView.annotations)
      self.dragCircle.center = CGPoint(x: -15, y: -15)
      self.locationManager.startMonitoringForRegion(CLCircularRegion(center: self.adjustableCircle!.coordinate, radius: self.adjustableCircle!.radius, identifier: id))
      let newOverlay = MKCircle(centerCoordinate: self.adjustableCircle!.coordinate, radius: self.adjustableCircle!.radius)
      self.adjustableCircle = nil
      self.mapView.removeOverlay(self.line)
      self.mapView.addOverlay(newOverlay)
    }
    
    alert.addTextFieldWithConfigurationHandler(nil)
    alert.addAction(action)
    self.presentViewController(alert, animated: true, completion: nil)

  }
  
  func removeRegion(notification : NSNotification) {
    if let info = notification.userInfo {
      let id = info["id"] as String
      
      let regions = locationManager.monitoredRegions
      var thisRegion : CLRegion?
      for region in regions {
        if let i = region as? CLRegion {
          if region.identifier == id {
            thisRegion = i
            println("Found region to stop monitoring")
          }
        }
      }
      
      self.locationManager.stopMonitoringForRegion(thisRegion)

    }
    
  }
  
  func reactivateRegion(notification: NSNotification) {
    if let info = notification.userInfo {
      let reminder = info["reminder"] as Reminder
      let latitude = CLLocationDegrees(reminder.latitude)
      let longitude = CLLocationDegrees(reminder.longitude)
      let coords = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      let radius = CLLocationDegrees(reminder.radius)
      
      locationManager.startMonitoringForRegion(CLCircularRegion(center: coords, radius: radius, identifier: reminder.locationID))
      println("Restarting region!")

    }
  }
  
  func loadOverlays(){
    mapView.removeOverlays(mapView.overlays)
    
    let request = NSFetchRequest(entityName: "Reminder")
    var error : NSError?
    let results = context.executeFetchRequest(request, error: &error) as [Reminder]
    
    for reminder in results {
      let latitude = CLLocationDegrees(reminder.latitude)
      let longitude = CLLocationDegrees(reminder.longitude)
      let coords = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      let radius = CLLocationDegrees(reminder.radius)
      self.mapView.addOverlay(MKCircle(centerCoordinate: coords, radius: radius))
    }
  }

  func showAddViewController() {
    
    if addVC.view.frame.origin.y >= self.view.frame.height {
      UIView.animateWithDuration(0.4,
        delay: 0.0,
        options: UIViewAnimationOptions.CurveEaseInOut,
        animations: { () -> Void in
          self.addVC.view.frame.origin.y -= 125
        },
        completion: nil)
    }
  }
  
  @IBAction func didPressLocateButton(sender: AnyObject) {
    let userLocation = locationManager.location
    let circle = MKCircle(centerCoordinate: userLocation.coordinate, radius: CLLocationDistance(500))
    mapView.setVisibleMapRect(circle.boundingMapRect, edgePadding: UIEdgeInsetsMake(0, 0, 0, 0), animated: true)
  }
  
  deinit{
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  

}