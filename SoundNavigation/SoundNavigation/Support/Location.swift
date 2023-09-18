//
//  Location.swift
//  SoundNavigation
//
//  Created by Jason on 2023/9/10.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import CoreLocation
import GoogleMaps

class LocationModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    @Published var withLatitude: CGFloat = 25.034012
    @Published var longitude: CGFloat = 121.564461
    @Published var sources: [String] = []
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestPermission() {
//        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else {
            return
        }
        withLatitude = latestLocation.coordinate.latitude
        longitude = latestLocation.coordinate.longitude
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
