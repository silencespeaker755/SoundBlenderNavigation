//
//  CoreLocation.swift
//  SoundNavigation
//
//  Created by Jason on 2023/9/14.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif

#if canImport(CoreLocation)
/**
 A geographic coordinate.
 
 This is a compatibility shim to keep the library’s public interface consistent between Apple and non-Apple platforms that lack Core Location. On Apple platforms, you can use `CLLocationCoordinate2D` anywhere you see this type.
 */
public typealias LocationCoordinate2D = CLLocationCoordinate2D
#else
/**
 A geographic coordinate.
 */
public struct LocationCoordinate2D {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
#endif
