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
  var dragCirclePoint: MKCircle?
  var dragCircle : UIView!
  var offset : (Double, Double)?
  var line : MKPolyline!
  
  
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
      locationManager.startUpdatingLocation()
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
    
    dragCircle = UIView(frame: CGRect(origin: CGPoint(x: -20, y: -20), size: CGSize(width: 20, height: 20)))
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
  
  func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
    println("Entered Region!")
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
    if overlay.isKindOfClass(MKPolyline) {
      let renderer = MKPolylineRenderer(overlay: overlay)
      renderer.strokeColor = UIColor.blackColor()
      renderer.lineWidth = 1
      renderer.lineDashPattern = [5,5]
      return renderer
    } else if overlay.isEqual(adjustableCircle) {
      let renderer = MKCircleRenderer(overlay: overlay)
      renderer.fillColor = UIColor.greenColor().colorWithAlphaComponent(0.2)
      renderer.lineWidth = 2
      renderer.strokeColor = UIColor.greenColor()
      return renderer
    } else {
      let renderer = MKCircleRenderer(overlay: overlay)
      renderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.2)
      renderer.lineWidth = 2
      renderer.strokeColor = UIColor.purpleColor()
      return renderer
      }
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
      mapView.removeOverlay(line)
      adjustableCircle = MKCircle(centerCoordinate: annotationCenter!, radius: CLLocation(latitude: lat1!, longitude: long1!).distanceFromLocation(CLLocation(latitude: lat2, longitude: long2)))
      mapView.addOverlay(adjustableCircle)
      
      var coordinatesForLine = [CLLocationCoordinate2D(latitude: lat2, longitude: long2), annotationCenter!]
      
      
      line = MKPolyline(coordinates: &coordinatesForLine, count: coordinatesForLine.count)
      
      mapView.addOverlay(line)
    }
  }
  
  func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
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
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
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
      self.locationManager.startMonitoringForRegion(CLCircularRegion(center: self.adjustableCircle!.coordinate, radius: self.adjustableCircle!.radius, identifier: textField.text))
      let newOverlay = MKCircle(centerCoordinate: self.adjustableCircle!.coordinate, radius: self.adjustableCircle!.radius)
      self.adjustableCircle = nil
      self.mapView.addOverlay(newOverlay)
    }
    
    alert.addTextFieldWithConfigurationHandler(nil)
    alert.addAction(action)
    self.presentViewController(alert, animated: true, completion: nil)

  }
  
  deinit{
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  

}