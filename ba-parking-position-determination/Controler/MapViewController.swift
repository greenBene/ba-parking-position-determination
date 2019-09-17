//
//  ViewController.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 13/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

class MapViewController: UIViewController, MKMapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    let regionRadius: CLLocationDistance = 1000
    let locationManager = CLLocationManager()
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        drawRoute()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        

        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.green
            lineView.lineWidth = 1
            return lineView
        }
        return MKOverlayRenderer()
    }
    
    func drawRoute(numberOfCoordinates: Int? = nil ){
        let coords: [CLLocationCoordinate2D] =
            [CLLocationCoordinate2D (latitude: 37.3228276, longitude: -122.0327804),
             CLLocationCoordinate2D(latitude: 37.3228288, longitude: -122.0349496),
             CLLocationCoordinate2D(latitude: 37.3238299, longitude: -122.0349674),
             CLLocationCoordinate2D(latitude: 37.323829, longitude: -122.035194),
             CLLocationCoordinate2D(latitude: 37.3251303, longitude: -122.0351992)
            ]
        
        let myPolyline = MKPolyline(coordinates: coords, count: coords.count)
        
        
        mapView.addOverlay(myPolyline)
        
    }
    
    // MARK: Actions
    
    @IBAction func detetimineParkingPositonButton(_ sender: Any) {
        print("Determine Parkign Position")
        
        let det =  ParkingPositionDetermination()
        
        det.determineParkingPosition()
        
    }
    

}
