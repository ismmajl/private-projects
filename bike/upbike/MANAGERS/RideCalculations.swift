//
//  RideCalculations.swift
//  upbike

import UIKit
import CoreLocation

class RideCalculations {
    
    static func getIntervalSpeedAndTime(locations: [CLLocation]) -> (Double, Double) {
        let count = locations.count
        guard count > 3 else { return (0,0) }
        let last = locations[count - 1]
        let prelast = locations[count - 3]
        let interval = last.timestamp.timeIntervalSince(prelast.timestamp).seconds
        let distance = last.distance(from: prelast)
        let calculatedSpeed = distance / interval
        if calculatedSpeed.isNaN || calculatedSpeed.isInfinite {
            return (0,0)
        }
        return (calculatedSpeed, Double(interval))
    }
    
    static func getPausedDistance(pausedLocations: [CLLocation]) -> Double {
        guard let firstLocation = pausedLocations.first, let lastLocation = pausedLocations.last, pausedLocations.count > 1 else { return 0 }
        let distance = abs(lastLocation.distance(from: firstLocation))
        let mutualHorizontalAccuracy = abs(firstLocation.horizontalAccuracy) + abs(lastLocation.horizontalAccuracy)
        return distance < mutualHorizontalAccuracy ? 0 : distance
    }
    
    static func getSlope(locations: [CLLocation]) -> Double {
        let count = locations.count
        guard count > 2 else { return 0 }
        let last = locations[count - 1]
        let prelast = locations[count - 2]
        
        let altitudeDifference = abs(last.altitude - prelast.altitude)
        let distanceDifference = last.distance(from: prelast)
        let slope = altitudeDifference / distanceDifference
        if slope.isNaN || slope.isInfinite {
            return 0
        }
        return slope
    }
}
