//
//  AppDelegate.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 13/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import UIKit
import CoreLocation
import Contacts // Needs to be loaded for postal adress
import RealmSwift
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let locationManager = CLLocationManager()
    static var currentLocation: CLLocation? = nil
    
    let realm = try! Realm()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
                
        
        print( "Realm database saved at: \(Realm.Configuration.defaultConfiguration.fileURL!)" )
        
//        try! realm.write {
//            realm.deleteAll()
//        }
        
        
        locationManager.requestAlwaysAuthorization()
        
        locationManager.delegate = self

        // start reveicing location
        locationManager.distanceFilter = 5
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        
        
        return true
    }

}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else {
            return
        }
        
        // Save location to realm
        
        AppDelegate.currentLocation = location
        
        saveLocaiton(location: location)
        
    }
    
    
    func saveLocaiton(location newLoc: CLLocation){
        do{
            try self.realm.write {
                
                let location = Location()
                
                location.latitude = newLoc.coordinate.latitude
                location.longitude = newLoc.coordinate.longitude
                location.altitude = newLoc.altitude
                location.timestamp = newLoc.timestamp
                location.horizontalAccuracy = newLoc.horizontalAccuracy
                location.verticalAccuracy = newLoc.verticalAccuracy
                location.level.value = newLoc.floor?.level
                
                realm.add(location)
                
                print("Added new location")
            }
        } catch {
            print("Error while adding new location to realm \(error)")
        }
    }
}

