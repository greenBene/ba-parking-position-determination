//
//  CarAnnotationView.swift
//  ba-parking-position-determination
//
//  Created by Benedikt Beckermann on 24/09/2019.
//  Copyright © 2019 Benedikt Beckermann. All rights reserved.
//

import UIKit
import MapKit

class CarAnnotationView: MKAnnotationView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        guard let carAnnotation = self.annotation as? CarAnnotation else { return }
      
        image = carAnnotation.image
    }
    
}
