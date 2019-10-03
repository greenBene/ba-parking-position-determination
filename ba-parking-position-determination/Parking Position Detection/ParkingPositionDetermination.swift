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
    
    let realm = try! Realm()
    
    let CONSECUTIVE_CAR_WINDOWS = 4
    let DISTANCE_THRESHOLD: Double = 100 //in meter
    let TIME_THRESHOLD: Double = 600 // in seconds
    
    enum ClassificationError: Error {
        case notEnoughData
        case noParkingLocationDetermined
        case runtimeError(String)
    }
    
    func getTransportationModeName(_ i: Int) -> String {
        switch i {
        case 0:
            return "car"
        case 1:
            return "walk"
        default:
            return ""
        }
    }
    
    
    
    
    func determineTransportationModes() throws -> ([CLLocation], [trans_modeOutput]) {
        var trajectory = loadTrajectory()
        trajectory = removeNoise(coords: trajectory)
        let classifier = trans_mode()
        let features = try featureExtraction(locations: trajectory)
        let output = try classifier.predictions(inputs: features)
        
        return (trajectory, output)
    }


    func determineParkingPosition() throws -> (CLLocation, [StayPoint]){
        
        // Load trajectory
        var trajectory = loadTrajectory()
        
        // Remove noise
        trajectory = removeNoise(coords: trajectory)
        
        let stayPoints = getStayPoints(locations: trajectory, distThresh: DISTANCE_THRESHOLD, timeThresh: TIME_THRESHOLD)
        
        // Cut it into trips based on stay points
        let trips = cutIntoTrips(stayPoints: stayPoints, trajectory: trajectory)
        
        let classifier = trans_mode()
        
        for trip in trips.reversed() {
            let features = try featureExtraction(locations: trip)
            
            let output = try classifier.predictions(inputs: features)
            
            if let loc =  try determineParkingPosLocation(trajectory: trip, labels: output) {
                return (loc, stayPoints)
            }
            
        }
        
        throw ClassificationError.noParkingLocationDetermined
        
    }
    
    
    
    
    private func determineParkingPosLocation(trajectory traj: [CLLocation], labels: [trans_modeOutput]) throws -> CLLocation? {
        var counter = 0
        
        for i in (0 ..< labels.count).reversed() {
            if( getTransportationModeName(Int(labels[i].target)) == "car" ){
                counter += 1
            } else {
                counter = 0
            }
            
            if(counter == CONSECUTIVE_CAR_WINDOWS){
                return traj[i + CONSECUTIVE_CAR_WINDOWS]
            }
        }
        
        throw ClassificationError.noParkingLocationDetermined
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
            
            .forEach { l in locations.append(l) }
        
        return locations
    }
    
    
    // MARK: Machine Learning Realated Functions
    
    
    private func featureExtraction(locations: [CLLocation]) throws -> [trans_modeInput] {
        var time: [Double] = Array() // Time difference in seconds
        var dist: [Double] = Array() // Distance in meters
        var bear: [Double] = Array() // Bearing in degree
        
        var velo: [Double] = Array() // Velocity in meters/second
        var acce: [Double] = Array() // Acceleration in meters/(second*second)
        var bearCh: [Double] = Array() // Bearing chagne in degree
        
        if(locations.count < 4) {
            throw ClassificationError.notEnoughData
        }
        
        
        for index in 0 ..< locations.count - 1 {
            
            let fst = locations[ index ]
            let snd = locations[ index + 1 ]
            
            
            let t = snd.timestamp.timeIntervalSince(fst.timestamp)
            let d = snd.distance(from: fst)
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
    
    // MARK: Stay Point based functions
    
    
    private func getStayPoints(locations: [CLLocation], distThresh: Double, timeThresh:Double) -> [StayPoint] {
        
        var i = 0; let pointNum = locations.count;
        var stayPoints: [StayPoint] = Array()
        
        while i < pointNum {
            var j = i + 1
            while j < pointNum {
                let p_i = locations[i]
                let p_j = locations[j]
                let dist = p_i.distance(from: p_j)
                
                if dist > distThresh {
                    let timeDelta = p_j.timestamp.timeIntervalSince(p_i.timestamp)
                    if timeDelta > timeThresh {
                        
                        let meanLoc = computeAverageCoordinate(coords: Array(locations[i...j]))
                        
                        stayPoints.append(
                            StayPoint(lat: meanLoc.latitude, lon: meanLoc.longitude,
                                                    arrivalTime: p_i.timestamp, leaveTime: p_j.timestamp,
                                                    distThresh: distThresh, timeThresh: timeThresh)
                        )
                    }
                    break
                }
                j = j+1
            }
            
            // Adaption of algorithm to also include entrance into latest potential staypoint
            
            if(j >= pointNum){
                stayPoints.append(
                    StayPoint(lat: locations[ i ].coordinate.latitude, lon: locations[ i ].coordinate.longitude,
                                            arrivalTime: locations[ i ].timestamp, leaveTime: locations[ i ].timestamp,
                                            distThresh: 0, timeThresh: 0)
                )
            }
            
            i = j // Algorithm in source lacks this line. Otherwise potential infinity loop.
        }
        
        let firstLocation = locations[0]
        stayPoints = [StayPoint(lat:firstLocation.coordinate.latitude , lon: firstLocation.coordinate.longitude,
                                arrivalTime: firstLocation.timestamp, leaveTime: firstLocation.timestamp, distThresh: 0, timeThresh: 0)] +
                     stayPoints
        
        return stayPoints
    }
    
    private func cutIntoTrips(stayPoints: [StayPoint], trajectory: [CLLocation]) -> [[CLLocation]] {
        var trips : [[CLLocation]]  = Array()
        
        for i in (0 ..< stayPoints.count - 1).reversed() {
            // From stayPoint i to stayPoint i+1
            let s_start = stayPoints[ i ]
            let s_stop = stayPoints[ i+1 ]
            
            let t_start = trajectory.firstIndex {
                t in
                return t.timestamp.compare(s_start.leaveTime) != .orderedAscending
            }
            
            let t_stop = trajectory.firstIndex {
                t in
                return t.timestamp.compare(s_stop.arrivalTime) != .orderedAscending
            }
            
            guard let t_start_i = t_start else { continue }
            guard let t_stop_i = t_stop else { continue }
            
            trips.append(Array(trajectory[t_start_i ... t_stop_i]))
        }
        
        return trips
    }
    
    
    private func removeNoise(coords: [CLLocation]) -> [CLLocation] {
        var cleaned: [CLLocation] = Array()
        
        guard cleaned.count > 5 else {
            return coords
        }
        
        for i in (2 ..< coords.count - 2) {
            let meanCoord = computeAverageCoordinate(coords: Array(coords[i-2 ... i+2]))
            
            cleaned.append(CLLocation(coordinate: meanCoord, altitude: coords[i].altitude, horizontalAccuracy: coords[i].horizontalAccuracy, verticalAccuracy: coords[i].verticalAccuracy, timestamp: coords[i].timestamp))
        }
        
        return cleaned
    }
    
    
    // MARK: Helper Methods
    
    private func computeAverageCoordinate(coords: [CLLocation]) -> CLLocationCoordinate2D{
        var lat: Double = 0
        var lon: Double = 0
        
        for c in coords {
            lat += c.coordinate.latitude
            lon += c.coordinate.longitude
        }
        
        lat /= Double(coords.count)
        lon /= Double(coords.count)
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func computeMeanCoordinate(coords: [CLLocation]) -> CLLocationCoordinate2D{
        var latArr: [Double] = Array()
        var lonArr: [Double] = Array()
        
        for c in coords {
            latArr += [c.coordinate.latitude]
            lonArr += [c.coordinate.longitude]
        }
        
        latArr.sorted()
        lonArr.sorted()
        
        let lat = latArr[latArr.count/2+1]
        let lon = lonArr[lonArr.count/2+1]
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
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
