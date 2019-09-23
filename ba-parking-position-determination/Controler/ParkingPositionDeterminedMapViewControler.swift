//
//  ParkingPositionDeterminedMapViewControler.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 17/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import Contacts

class ParkingPositionDeterminedMapViewControler: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var informationView: UIView!
    @IBOutlet weak var parkingLocationInformationLabel: UILabel!
    
    var carLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    
    var geoCoder = CLGeocoder()
    var trajectory: [CLLocation] = Array()
    var labels: [trans_modeOutput] = Array()
    
    override func viewDidLoad() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.setCenter(carLocation.coordinate, animated: true)
        
        drawTrajectory()
        
        showCarLocation()
        
        setCarLocationInformation()
        
        additionalSafeAreaInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: informationView.bounds.height, right: 0.0)

    }
    
    
    func drawTrajectory() {
        var overlays: [MKOverlay] = Array()
        
        for index in 0 ..< labels.count {
            let coords: [CLLocationCoordinate2D] = [trajectory[index].coordinate, trajectory[index+1].coordinate, trajectory[index+2].coordinate]
            
            switch labels[index].target {
            case 0: overlays.append(BikeMKPolyline(coordinates: coords, count: coords.count))
            case 1: overlays.append(CarMKPolyline(coordinates: coords, count: coords.count))
            case 2: overlays.append(TrainMKPolyline(coordinates: coords, count: coords.count))
            case 3: overlays.append(WalkMKPolyline(coordinates: coords, count: coords.count))
            default: print("Should not happen")
            }
        }
        
        mapView.addOverlays(overlays)
    }
    
    func showCarLocation(){
        let carLocAnnotation = MKPointAnnotation()
        carLocAnnotation.title = "Your Car"
        carLocAnnotation.coordinate = carLocation.coordinate
        print(carLocation)
        mapView.addAnnotation(carLocAnnotation)
    }
    
    func setCarLocationInformation(){
        var description = ""
        
        geoCoder.reverseGeocodeLocation(carLocation) {
            (placemarks, error) in
            if let adress = placemarks?.first?.postalAddress {
                description = CNPostalAddressFormatter.string(from:adress, style: .mailingAddress) + "\n\n"
                
                if let currentLoc = AppDelegate.currentLocation{
                    description += String(format: "Distance: %.1f km", currentLoc.distance(from: self.carLocation)/1000)
                }
                
                description += "\n"
                
                if let currentAlt = AppDelegate.currentLocation?.altitude {
                    description += String(format: "Relative Altitude: %d m",  Int(self.carLocation.altitude - currentAlt))
                }
                
                description += "\n"
                
                if let f = self.carLocation.floor?.level {
                   description = description + "Floor: " + String(f)
                } else {
                    description += "\n"
                }
                
                self.parkingLocationInformationLabel.text = description
            }
        }
    
    

        
        
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        
        self.dismiss(animated: false, completion: nil)
        
    }
    
    @IBAction func reportAccuracyButton(_ sender: Any) {
        
        
    }
    
    @IBAction func getDirectionsButton(_ sender: Any) {
        
        let item = MKMapItem(placemark: MKPlacemark(coordinate: carLocation.coordinate))
        item.name = "car"
        
        item.openInMaps(launchOptions: nil)

    }
    
}

extension ParkingPositionDeterminedMapViewControler: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            
            if overlay is BikeMKPolyline {
                lineView.strokeColor = UIColor.green
            } else if overlay is CarMKPolyline {
                lineView.strokeColor = UIColor.black
            } else if overlay is TrainMKPolyline {
                lineView.strokeColor = UIColor.blue
            } else if overlay is WalkMKPolyline {
                lineView.strokeColor = UIColor.red
            }
            lineView.lineWidth = 1
            return lineView
        }
        return MKOverlayRenderer()
    }
    
}


class BikeMKPolyline: MKPolyline {}
class CarMKPolyline: MKPolyline {}
class TrainMKPolyline: MKPolyline {}
class WalkMKPolyline: MKPolyline {}

