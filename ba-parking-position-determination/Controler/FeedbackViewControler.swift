//
//  FeedbackControler.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 23/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import UIKit
import MapKit
import Alamofire

class FeedbackViewControler : UIViewController {
    
    @IBOutlet weak var sharedInformationLabel: UILabel!
    
    let POST_ACCURACY_URL = "http://benedikt.click:8080/post"
    
    var carLocation: CLLocation?
    
    var distance: Double = -1
    var model: String = ""
    var system: String = ""
    var timeSinceParking: Double = -1
    
    override func viewDidLoad() {
        
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
    
    func postAccuracyData(parameters: [String: String] ){
        
        Alamofire.request(POST_ACCURACY_URL, method: .post, parameters: parameters).response { (response) in

            let statusCode = response.response?.statusCode
            
            if statusCode == 200 {
                let alert = UIAlertController(title: "Success", message: "You successfully reported the accuracy. Thank you!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true)
            } else {
                if statusCode == 400 {
                    self.showPopupMessage(title: "Failure", msg: "The application was not able to report the accuracy. Please try again later")
                } else {
                    self.showPopupMessage(title: "Failure", msg: "The server was not able to save the accuracy. Please try again later")
                }
            }
        }
    }
    
    func showPopupMessage(title: String, msg: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    
    // MARK: Button Actions

    @IBAction func sendAccuracy(_ sender: Any) {

        let parameters: [String: String] = ["model": model, "os": system, "timeSinceParking": String(timeSinceParking), "accuracy": String(distance)]
        
        let alert = UIAlertController(title: title, message: "Are you at the location of your parked car?" , preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "No", style: .destructive, handler: { (action) in
            self.showPopupMessage(title: "Attention", msg: "Please report the accuracy when you are at the location of your car")
        }))
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            self.postAccuracyData(parameters: parameters)
        }))
        self.present(alert, animated: true)

    }
    
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
