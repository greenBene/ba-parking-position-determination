//
//  ParkingPositionDetection.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 16/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation

class ParkingPositionDetermination {
    
    enum ClassificationError: Error {
        case runtimeError(String)
    }
    
    enum TransportationMode {
        case bike
        case car
        case train
        case walk
    }
    
    func getTransportationModeName(_ i: Int) -> String {
        switch i {
        case 0:
            return "bike"
        case 1:
            return "car"
        case 2:
            return "train"
        case 3:
            return "walk"
        default:
            return ""
        }
    }
    
    let realm = try! Realm()
    
    
    
    func determineParkingPosition() throws -> ([CLLocation], [trans_modeOutput], CLLocation?){
        
        let trajectory = loadTrajectory()

        var output: [trans_modeOutput] = Array()
        
    
        do {
            
            let features = try featureExtraction(locations: trajectory)
            
            let classifier = trans_mode()
            
            output = try classifier.predictions(inputs: features)

        } catch {
            throw error
        }
        
        
        var counter = 0
        
        var loc: CLLocation? = nil
        
        for i in (0 ..< output.count).reversed() {
            if( getTransportationModeName(Int(output[i].target)) == "car" ){
                counter += 1
            } else {
                counter = 0
            }
            
            if(counter == 2){
                loc = trajectory[i + 5]
            }
            
        }
        
        return (trajectory, output, loc)
        
    }
    
    private func loadTrajectory() -> [CLLocation] {
        var locations: [CLLocation] = Array()
        
        realm.objects(Location.self).sorted(byKeyPath: "timestamp", ascending: true)
            .map({(loc: Location) -> CLLocation in
                return CLLocation(coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude),
                                  altitude: loc.altitude,
                                  horizontalAccuracy: loc.horizontalAccuracy,
                                  verticalAccuracy: loc.verticalAccuracy,
                                  timestamp: loc.timestamp)})
            .forEach { l in locations.append(l)}
        
        return locations
    }
    
    private func featureExtraction(locations: [CLLocation]) throws -> [trans_modeInput] {
        var time: [Double] = Array() // Time difference in seconds
        var dist: [Double] = Array() // Distance in meters
        var bear: [Double] = Array() // Bearing in degree
        
        var velo: [Double] = Array() // Velocity in meters/second
        var acce: [Double] = Array() // Acceleration in meters/(second*second)
        var bearCh: [Double] = Array() // Bearing chagne in degree
        
        
        for index in 0 ..< locations.count - 1 {
            
            let fst = locations[ index ]
            let snd = locations[ index + 1 ]
            
            
            let t = fst.timestamp.timeIntervalSince(snd.timestamp)
            let d = fst.distance(from: snd)
            let b = bearing(lat1: fst.coordinate.latitude, lon1: fst.coordinate.longitude,
                            lat2: snd.coordinate.latitude, lon2: snd.coordinate.longitude)
            
            let v = d/t
            
            time.append(t)
            dist.append(d)
            bear.append(b)
            
            velo.append(v)
            
            if(index != 0) {
                
                let a = (velo[ index ] - velo[ index - 1 ]) / time[ index - 1 ]
                let brCh = 180.0 - abs(abs(bear[ index - 1 ] - bear[ index ] ) - 180.0)
                
                acce.append(a)
                bearCh.append(brCh)
            }
        }
        
        // widows
        
        var features: [trans_modeInput] = Array()

        if locations.count < 4 {
            throw ClassificationError.runtimeError("not enough location data collected")
        }

        
        for index in 0 ..< locations.count - 4 {
            
            let v0 = velo[ index ]
            let v1 = velo[ index + 1 ]
            let v2 = velo[ index + 2 ]
            
            let max_v = max(v0, v1, v2)
            let min_v = min(v0, v1, v2)
            let range_v = max_v - min_v
            let sum_v = v0 + v1 + v2
            let avg_v = sum_v / 3
            let var_v = (pow(v0 - avg_v, 2)
                       + pow(v1 - avg_v, 2)
                       + pow(v2 - avg_v, 2))
                        / 3
            
            let a0 = acce[ index ]
            let a1 = acce[ index + 1 ]
            let a2 = acce[ index + 2 ]
            
            let max_a = max(a0, a1, a2)
            let min_a = min(a0, a1, a2)
            let range_a = max_a - min_a
            let sum_a = a0 + a1 + a2
            let avg_a = sum_a / 3
            let var_a = (pow(a0 - avg_a, 2)
                + pow(a1 - avg_a, 2)
                + pow(a2 - avg_a, 2))/3
            
            let bC0 = bearCh[ index ]
            let bC1 = bearCh[ index + 1 ]
            let bC2 = bearCh[ index + 2 ]
            
            let max_bC = max(bC0, bC1, bC2)
            let min_bC = min(bC0, bC1, bC2)
            let range_bC = max_bC - min_bC
            let sum_bC = bC0 + bC1 + bC2
            let avg_bC = sum_bC / 3
            let var_bC = (pow(bC0 - avg_bC, 2)
                + pow(bC1 - avg_bC, 2)
                + pow(bC2 - avg_bC, 2))/3
            
       
            features.append( trans_modeInput(v0: v0, v1: v1, v2: v2, a0: a0, a1: a1, a2: a2, brCh0: bC0, brCh1: bC1, brCh2: bC2,
                                             max_a_: max_a, min_a_: min_a, range_a_: range_a, sum_a_: sum_a, avg_a_: avg_a, var_a_: var_a,
                                             max_v_: max_v, min_v_: min_v, range_v_: range_v, sum_v_: sum_v, avg_v_: avg_v, var_v_: var_v,
                                             max_brCh_: max_bC, min_brCh_: min_bC, range_brCh_: range_bC, sum_brCh_: sum_bC, avg_brCh_: avg_bC, var_brCh_: var_bC))
            
            
        }
        
        return features
    }
        
    private func bearing(lat1: Double, lon1: Double, lat2: Double, lon2:Double) -> Double {
        let lat1_r = deg2rad(x: lat1)
        let lon1_r = deg2rad(x: lon1)
        let lat2_r = deg2rad(x: lat2)
        let lon2_r = deg2rad(x: lon2)
        
        let y = sin(abs(lon2_r-lon1_r)) * cos(lat2_r)
        let x = cos(lat1_r) * sin(lat2_r) - sin(lat1_r) * cos(lat2_r) * cos(abs(lon2_r-lon1_r))
        
        
        return rad2deg(x: atan2(y, x))
    }
        
    private func rad2deg(x: Double) -> Double {
        return x / 180.0 * .pi
    }
    
    private func deg2rad(x: Double) -> Double {
        return x * .pi / 180.0
    }
        
    
}
