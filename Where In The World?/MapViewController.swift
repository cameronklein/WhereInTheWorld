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

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
  
  let locationManager = CLLocationManager()
  var adjustableCircle : MKCircle?
  var dragCircle : UIView!
  var annotationCenter : CLLocationCoordinate2D?
  var addVC : AddReminderViewController!
  let backgroundQueue = NSOperationQueue()
  
  @IBOutlet weak var mapView: MKMapView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "cancelPressed", name: "cancelPressed", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "addReminder", name: "addReminder", object: nil)
    
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
    
    self.mapView.delegate = self
    locationManager.delegate = self
    
    switch CLLocationManager.authorizationStatus() {
    case .Authorized:
      println("authorized")
      self.mapView.showsUserLocation = true
    case .NotDetermined:
      println("not determined")
      self.locationManager.requestAlwaysAuthorization()
    case .Restricted:
      println("restricted")
    case .Denied:
      println("denied")
    default:
      println("default")
    }
    
    dragCircle = UIView(frame: CGRect(origin: CGPoint(x: -15, y: -15), size: CGSize(width: 15, height: 15)))
    dragCircle.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.7)
    dragCircle.layer.cornerRadius = dragCircle.frame.height / 2
    dragCircle.clipsToBounds = true
    self.view.addSubview(dragCircle)
    
    let circlePanRecognizer = UIPanGestureRecognizer()
    circlePanRecognizer.addTarget(self, action: "didPanCircle:")
    dragCircle.addGestureRecognizer(circlePanRecognizer)
    
    addVC = AddReminderViewController(nibName:"AddReminderViewController", bundle: NSBundle.mainBundle())
    self.addChildViewController(addVC)
    let screenHeight = self.view.frame.height
    let screenWidgth = self.view.frame.width
    addVC.view.frame = CGRect(origin: CGPoint(x: 0, y: screenHeight), size: CGSize(width: screenWidgth, height: 125.0))
    self.view.addSubview(addVC.view)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    
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
  
  func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
    
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
    adjustableCircle = MKCircle(centerCoordinate: view.annotation.coordinate, radius: 150000.0)
    mapView.addOverlay(adjustableCircle)
    placeDragCircle()
    showAddViewController()
    

  }
  
  func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
    let renderer = MKCircleRenderer(overlay: overlay)
    renderer.fillColor = UIColor.greenColor().colorWithAlphaComponent(0.2)
    renderer.lineWidth = 2
    renderer.strokeColor = UIColor.greenColor()
    
    return renderer
  }
  
  func showAddViewController() {
    
    UIView.animateWithDuration(0.4,
      delay: 0.0,
      options: UIViewAnimationOptions.CurveEaseInOut,
      animations: { () -> Void in
        self.addVC.view.frame.origin.y -= 125
      },
      completion: nil)
  }
  
  func didPinch(sender: UIPinchGestureRecognizer){
    placeDragCircle()
  }
  
  func didPan(sender: UIPanGestureRecognizer){
    if sender.state == UIGestureRecognizerState.Began {
      let point = sender.locationInView(self.view)
      if dragCircle.pointInside(point, withEvent: nil) {
        println("Point Inside!")
      }
    }
    placeDragCircle()
  }
  
  func didPanCircle(sender: UIPanGestureRecognizer){
    if sender.state == UIGestureRecognizerState.Changed {
      let point = sender.locationInView(self.view)
      dragCircle.center = point
      
      let coord = mapView.convertPoint(point, toCoordinateFromView: self.view)
      println("\(coord.longitude)")
      let lat1 = annotationCenter?.latitude
      let long1 = annotationCenter?.longitude
      let lat2 = coord.latitude
      let long2 = coord.longitude
      annotationCenter?.longitude
      
      mapView.removeOverlay(adjustableCircle)
      adjustableCircle = MKCircle(centerCoordinate: annotationCenter!, radius: CLLocation(latitude: lat1!, longitude: long1!).distanceFromLocation(CLLocation(latitude: lat2, longitude: long2)))
      mapView.addOverlay(adjustableCircle)
  
    }
  }
  
  func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
    for view in views {
      let thisView = view.annotation as MKAnnotation
      backgroundQueue.addOperationWithBlock({ () -> Void in
        NSThread.sleepForTimeInterval(0.4)
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
          mapView.selectAnnotation(thisView, animated: true)
        })
      })
      
      
    }
  }

  func mapView(mapView: MKMapView!, regionWillChangeAnimated animated: Bool) {
    placeDragCircle()
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  func placeDragCircle(){
    if adjustableCircle != nil {
      let coord = adjustableCircle!.coordinate
      let newCoord = CLLocationCoordinate2DMake(coord.latitude, coord.longitude + (adjustableCircle!.radius * 0.0000115))
      dragCircle!.center = mapView.convertCoordinate(newCoord, toPointToView: self.view)
      
      let circleCenter = mapView.convertCoordinate(coord, toPointToView: self.view)
      
      let context = UIGraphicsGetCurrentContext()
      CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
      CGContextSetLineWidth(context, 2.0)
      CGContextMoveToPoint(context, circleCenter.x, circleCenter.y)
      CGContextAddLineToPoint(context, dragCircle.center.x, dragCircle.center.y)
      CGContextStrokePath(context)
      self.view.setNeedsDisplay()
      
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
      reminder.setValue(NSDate(), forKey: "createdAt")
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
    }
    
    alert.addTextFieldWithConfigurationHandler(nil)
    alert.addAction(action)
    self.presentViewController(alert, animated: true, completion: nil)

  }
  
  deinit(){
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  

}