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

class LoadingMapViewController: UIViewController, MKMapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var informationView: UIView!
    
    let regionRadius: CLLocationDistance = 1000
    let locationManager = CLLocationManager()
    let realm = try! Realm()
    
    var carLocation: CLLocation? = nil
    var trajectory: [CLLocation] = Array()
    var labels: [trans_modeOutput] = Array()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        mapView.showsCompass = true
        mapView.showsScale = true
        
        additionalSafeAreaInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: informationView.bounds.height, right: 0.0)
        
    }
    
    
    // MARK: Actions
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let con = segue.destination as! ParkingPositionDeterminedMapViewControler
        con.carLocation = carLocation!
        con.trajectory = trajectory
        con.labels = labels
    }
    
    @IBAction func detetimineParkingPositonButton(_ sender: Any) {
        print("Determine Parkign Position")

        let det =  ParkingPositionDetermination()
        
        do {
            (trajectory, labels, carLocation) = try det.determineParkingPosition()
            
            performSegue(withIdentifier: "showCar", sender: nil)
            
        } catch{
            print("There was an issue while determining the parking locaiton")
        }
        
        
        
        
    }
    

}

