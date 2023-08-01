//
//  RideInfo.swift
//  combike

import UIKit
import RealmSwift

class RideInfo: Object {
    
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var rideId: String = ""
    @Persisted var time: Int = 0
    @Persisted var date: Date = Date()
    @Persisted var distance: Double = 0
    @Persisted var speed: Double = 0
    @Persisted var calories: Int = 0
    @Persisted var altitude: Int = 0
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    //@Persisted var coordinates: RideCoordinate?
    
    static func create(time: Int, date: Date, distance: Double, speed: Double, calories: Int, altitude: Int, coordinates: RideCoordinate) -> RideInfo {
        let rideInfo = RideInfo()
        rideInfo.id = String().generateRandomId(length: 128)
        rideInfo.time = time
        rideInfo.date = date
        rideInfo.distance = distance
        rideInfo.speed = speed
        rideInfo.calories = calories
        rideInfo.altitude = altitude
        rideInfo.latitude = coordinates.latitude
        rideInfo.longitude = coordinates.longitude
        
        return rideInfo
    }
}
