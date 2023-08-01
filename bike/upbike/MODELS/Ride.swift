//
//  Ride.swift
//  combike

import Foundation
import RealmSwift
import CoreLocation
import Realm

enum Version: String {
    case v1 = "v1"
    case v2 = "v2"
}

enum RideState {
    case start
    case continuing
    case paused
    case stopped
}

enum RideMode: String {
    case free = "Free Ride"
    case time = "Time"
    case distance = "Distance"
    case calories = "Calories"
    
    var name: String {
        switch self {
        case .free: return "General.label.DefaultRide".localized()
        case .time: return "General.label.Time".localized()
        case .distance: return "General.label.Distance".localized()
        case .calories: return "General.label.Calories".localized()
        }
    }
    
    var desc : String {
        switch self {
        case .free: return "RideMode.desc.Default".localized()
        case .time: return "RideMode.desc.Time".localized()
        case .distance: return "RideMode.desc.Distance".localized()
        case .calories: return "RideMode.desc.Calories".localized()
        }
    }
    
    var img : UIImage? {
        switch self {
        case .free: return UIImage(named: "free ride white")
        case .time: return UIImage(named: "time icon white")
        case .distance: return UIImage(named: "distance white")
        case .calories: return UIImage(named: "calories white")
        }
    }
    
    var imgBase : UIImage? {
        switch self {
        case .free: return UIImage(named: "free ride")
        case .time: return UIImage(named: "time icon")
        case .distance: return UIImage(named: "distance")
        case .calories: return UIImage(named: "calories")
        }
    }
}

class Ride: Object {
    
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var isCompleted: Bool = false
    @Persisted var title: String = ""
    @Persisted var desc: String = ""
    @Persisted var rideFeel: Double = 0.5
    
    @Persisted var modeType: String = ""
    var mode: RideMode {
        get { return RideMode(rawValue: modeType)! }
        set { modeType = newValue.rawValue }
    }
    
    @Persisted var versionType: String = ""
    var version: Version {
        get { return Version(rawValue: versionType) ?? .v1 }
        set { versionType = newValue.rawValue }
    }
    
    @Persisted var photos: MutableSet<String> = MutableSet<String>()
    @Persisted var rideInfos: MutableSet<RideInfo> = MutableSet<RideInfo>()
    
    //v1 data
    @Persisted var date: Date = Date()
    @Persisted var duration: Int = 0
    @Persisted var distance: Double = 0
    @Persisted var maxSpeed: CLLocationSpeed = 0.0
    @Persisted var avgSpeed: CLLocationSpeed = 0.0
    @Persisted var calories: Int = 0
    
    
    static func create(mode: RideMode, version: Version, title: String = "", desc: String = "", rideFeel: Double = 0, photos: [String] = [], rideInfos: [RideInfo] = [], date: Date = Date(), duration: Int = 0, distance: Double = 0, maxSpeed: CLLocationSpeed = 0.0, avgSpeed: CLLocationSpeed = 0.0, calories: Int = 0) -> Ride {
        let ride        = Ride()
        ride.id         = String().generateRandomId(length: 128)
        ride.mode       = mode
        ride.version    = version
        ride.modeType   = mode.rawValue
        ride.title      = title
        ride.desc       = desc
        ride.rideFeel   = rideFeel
        
        //v1 data
        ride.date       = date
        ride.duration   = duration
        ride.distance   = distance
        ride.maxSpeed   = maxSpeed
        ride.avgSpeed   = avgSpeed
        ride.calories   = calories
        
        if ride.version == .v1 {
            ride.isCompleted = true
        }
        
        return ride
    }
    
    var startDateC: Date {
        //v1 data
        if version == .v1 {
            return date
        }
        //v2 data
        let rideDates = rideInfos.map {$0.date}
        if let startDate = rideDates.min() {
            return startDate
        }
        if let startDate = rideDates.sorted(by: {$0 < $1}).first {
            return startDate
        }
        return Date()
    }
    
    var endDateC: Date {
        //v1 data
        if version == .v1 {
            return date.addingTimeInterval(Double(duration))
        }
        //v2 data
        let rideDates = rideInfos.map {$0.date}
        if let startDate = rideDates.max() {
            return startDate
        }
        if let startDate = rideDates.sorted(by: {$0 > $1}).first {
            return startDate
        }
        return Date()
    }
    
    //duration in seconds
    var durationC: Int {
        //v1 data
        if version == .v1 {
            return self.duration
        }
        //v2 data
        //return endDateC.secondsBetween(date: startDateC)
        guard let time = rideInfos.last?.time else { return 0 }
        return time
    }
    
    var distanceC: Double {
        //v1 data
        if version == .v1 {
            return self.distance
        }
        //v2 data
        //guard let distance = rideInfos.map({$0.distance}).max() else { return 0 }
        guard let distance = rideInfos.last?.distance else { return 0 }
        return distance
    }
    
    var minSpeedC: Double {
        guard let minSpeed = rideInfos.map({$0.speed}).min() else { return 0 }
        return minSpeed
    }
    
    var maxSpeedC: Double {
        //v1 data
        if version == .v1 {
            return self.maxSpeed
        }
        //v2 data
        guard let maxSpeed = rideInfos.map({$0.speed}).max() else { return 0 }
        return maxSpeed
    }
    
    //average speed in m/s
    var averageSpeedC: Double {
        //v1 data
        if version == .v1 {
            return self.avgSpeed
        }
        //v2 data
        //return  distance != 0 && duration != 0 ? distance / Double(duration) : 0
        let averageSpeed = Utils.averageSpeedOnly(speeds: rideInfos.map({$0.speed}))
        return averageSpeed.isNaN || averageSpeed.isInfinite ? 0 : averageSpeed
    }
    
    var minAltitudeC: Int {
        guard let minAltitude = rideInfos.map({$0.altitude}).min() else { return 0 }
        return minAltitude
    }
    
    var maxAltitudeC: Int {
        guard let maxAltitude = rideInfos.map({$0.altitude}).max() else { return 0 }
        return maxAltitude
    }
    
    var caloriesC: Int {
        //v1 data
        if version == .v1 {
            return self.calories
        }
        //v2 data
        //guard let calories = rideInfos.map({$0.calories}).max() else { return 0 }
        guard let calories = rideInfos.last?.calories else { return 0 }
        return calories
    }
    
    func deleteRideInfos() {
        let rideInfos: [RideInfo] = Ride.all().toArray()
        let filteredRideInfos = rideInfos.filter({$0.id == id})
        filteredRideInfos.delete()
    }
    
    var subtitle: String {
        return endDateC.toCostumFormat + " - " + Utils.secondsToHoursMinutesSeconds(seconds: durationC)
    }
}
