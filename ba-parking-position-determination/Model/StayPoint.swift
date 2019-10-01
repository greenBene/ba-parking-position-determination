//
//  StayPoint.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 01/10/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import Foundation
import MapKit

class StayPoint {
    let coordinates: CLLocationCoordinate2D
    let arrivalTime: Date
    let leaveTime: Date
    let distanceThreshold: Double
    let timeThreshold: Double
    
    
    init(lat latitude: CLLocationDegrees, lon longitude: CLLocationDegrees, arrivalTime: Date, leaveTime: Date, distThresh distanceThreshold: Double, timeThresh timeThreshold: Double) {
        self.arrivalTime = arrivalTime
        self.leaveTime = leaveTime
        self.distanceThreshold = distanceThreshold
        self.timeThreshold = timeThreshold
        self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
    }
    
}
