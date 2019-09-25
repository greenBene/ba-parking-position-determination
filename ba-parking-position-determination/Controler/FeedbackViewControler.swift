//
//  FeedbackControler.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 23/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import UIKit
import MapKit

class FeedbackViewControler : UIViewController {
    
    @IBOutlet weak var sharedInformationLabel: UILabel!
    
    var carLocation: CLLocation?
    
    var distance: Double = -1
    var model: String = ""
    var system: String = ""
    var timeSinceParking: Double = -1
    
    override func viewDidLoad() {
        // determine stuff.
        determineInformation()
        
    }
    
    
    func determineInformation(){
        
        guard let carL = carLocation else {
            return
        }
        
        let currentL = AppDelegate.currentLocation!
        
        distance = carL.distance(from: currentL)
        timeSinceParking = currentL.timestamp.timeIntervalSince(carL.timestamp)
        
        let device = UIDevice()
        
        model = device.model
        
        system = device.systemName + device.systemVersion
        
        
        
        let message = String(format: "Accuracy: %d m\n", Int(distance))
                    + String(format: "Time Since Parking: %.1f min\n", timeSinceParking/60)
                    + "Model: \(model)\n"
                    + "System: \(system)\n"
        
        sharedInformationLabel.text = message
        
    }
    
    
    
    
    
    // MARK: Button Actions

    @IBAction func sendAccuracy(_ sender: Any) {
        
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
