//
//  Location.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 16/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import Foundation
import RealmSwift

class Location: Object {
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var altitude: Double = 0
    let level = RealmOptional<Int>()
    @objc dynamic var timestamp: Date = Date()
    
    @objc dynamic var horizontalAccuracy: Double = 0
    @objc dynamic var verticalAccuracy: Double = 0
    
}
