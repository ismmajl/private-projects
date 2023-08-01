//
//  RideCoordinate.swift
//  combike

import Foundation
import RealmSwift
import CoreLocation

class RideCoordinate: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    
    static func create(coordinate: CLLocationCoordinate2D) -> RideCoordinate {
        let c       = RideCoordinate()
        c.id        = String().generateRandomId(length: 128)
        c.latitude  = coordinate.latitude
        c.longitude = coordinate.longitude
        return c
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude)
    }
}


