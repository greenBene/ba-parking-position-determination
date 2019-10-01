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
            
            print(labels[index].target)
            
            switch labels[index].target {
            case 0: overlays.append(CarMKPolyline(coordinates: coords, count: coords.count))
            case 1: overlays.append(WalkMKPolyline(coordinates: coords, count: coords.count))
            default: print("Should not happen")
            }
        }
        
        mapView.addOverlays(overlays)
    }
    
    func showCarLocation(){
        let carLocAnnotation = CarAnnotation(coordinate: carLocation.coordinate)
        
        mapView.addOverlay(MKCircle(center: carLocAnnotation.coordinate, radius: 50))
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is FeedbackViewControler {
            let seg = segue.destination as! FeedbackViewControler
            seg.carLocation = carLocation
        }
    }
    
    // MARK: Button Actions
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    
    @IBAction func getDirectionsButton(_ sender: Any) {
        
        let item = MKMapItem(placemark: MKPlacemark(coordinate: carLocation.coordinate))
        item.name = "My Car"
        
        item.openInMaps(launchOptions: nil)

    }
    
}

// MARK: MKMapViewDelegate

extension ParkingPositionDeterminedMapViewControler: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.lineWidth = 1
            
            if overlay is CarMKPolyline {
                lineView.strokeColor = UIColor.blue
            } else if overlay is WalkMKPolyline {
                lineView.strokeColor = UIColor.green
            }
            
            return lineView
        } else if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.darkGray.withAlphaComponent(0.3)
            renderer.strokeColor = UIColor.darkGray
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = CarAnnotationView(annotation: annotation, reuseIdentifier: "Car")
        annotationView.canShowCallout = true
        return annotationView
    }
    
}


class BikeMKPolyline: MKPolyline {}
class CarMKPolyline: MKPolyline {}
class TrainMKPolyline: MKPolyline {}
class WalkMKPolyline: MKPolyline {}

