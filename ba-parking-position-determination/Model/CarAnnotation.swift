//
//  CarLocation.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 13/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import Foundation
import MapKit

class CarAnnotation: NSObject, MKAnnotation {
    
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        return "CAR"
    }
}
