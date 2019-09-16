//
//  ViewController.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 13/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    let regionRadius: CLLocationDistance = 1000
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
    }

}
