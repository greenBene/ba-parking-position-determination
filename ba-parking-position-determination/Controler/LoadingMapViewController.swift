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
    
    let locationManager = CLLocationManager()
    let realm = try! Realm()
    
    var carLocation: CLLocation? = nil
    var stayPoints: [StayPoint] = Array()
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
    
    func showErrorMessage(message: String){
        let alert = UIAlertController(title: "Attention", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let con = segue.destination as! ParkingPositionDeterminedMapViewControler
        con.carLocation = carLocation!
        con.stayPoints = stayPoints
        con.labels = labels
        con.trajectory = trajectory
    }
    
    // MARK: Actions
    
    @IBAction func detetimineParkingPositonButton(_ sender: Any) {

        let det =  ParkingPositionDetermination()
        
        
        do {
            (carLocation, stayPoints) = try det.determineParkingPosition()
            (trajectory, labels) = try det.determineTransportationModes()
            
            performSegue(withIdentifier: "showCar", sender: nil)
            
        } catch ParkingPositionDetermination.ClassificationError.noParkingLocationDetermined {
            showErrorMessage(message: "We cannot detect enough car movement. Please try again after using a car.")
        } catch ParkingPositionDetermination.ClassificationError.notEnoughData {
            showErrorMessage(message: "Not enough data is collected. Please try again later.")
        } catch {
            showErrorMessage(message: error.localizedDescription)
        }
        
    }
    

}

