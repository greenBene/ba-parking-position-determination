//
//  CarAnnotation.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 24/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import Foundation
import MapKit

class CarAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String? = "Your Car"
    let image = UIImage(named: "Car")
    
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
