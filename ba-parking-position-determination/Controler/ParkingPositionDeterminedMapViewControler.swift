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

class ParkingPositionDeterminedMapViewControler: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var carLocation: CLLocation? = nil
    var trajectory: [CLLocation] = Array()
    var labels: [trans_modeOutput] = Array()
    
    override func viewDidLoad() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        mapView.showsCompass = true
        mapView.showsScale = true
        
        drawTrajectory()
        
        showCarLocation()

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
        if let coord = carLocation?.coordinate {
            let carLocAnnotation = MKPointAnnotation()
            carLocAnnotation.title = "CAR"
            carLocAnnotation.coordinate = coord
            mapView.addAnnotation(carLocAnnotation)
        }
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        
        self.dismiss(animated: false, completion: nil)
        
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

