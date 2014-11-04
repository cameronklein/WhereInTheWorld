//
//  ViewController.swift
//  Where In The World?
//
//  Created by Cameron Klein on 11/4/14.
//  Copyright (c) 2014 Cameron Klein. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
  
  let locationManager = CLLocationManager()
  
  @IBOutlet weak var mapView: MKMapView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let longPressRecognizer = UILongPressGestureRecognizer()
    longPressRecognizer.addTarget(self, action: "didPressLongingly:")
    mapView.addGestureRecognizer(longPressRecognizer)
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
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    
  }
  
  func didPressLongingly(sender: UILongPressGestureRecognizer) {
    
    if sender.state == .Began {
      let touchedAt = sender.locationInView(mapView)
      let touchCoord = self.mapView.convertPoint(touchedAt, toCoordinateFromView: self.mapView)
      
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
    
    
    
  }
  
  
  
  
}