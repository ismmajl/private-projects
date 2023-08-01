//
//  RideManager.swift
//  combike

import UIKit
import CoreLocation
import MapKit
import RealmSwift
import FirebaseAnalytics

protocol RideManagerDelegate: AnyObject {
    func ride(manager: RideManager, didUpdateTime time: String, seconds: Int)
    func ride(manager: RideManager, didUpdateSpeed speed: String, progressPercentage: Double)
    func ride(manager: RideManager, didUpdateAverageSpeed speed: String)
    func ride(manager: RideManager, didUpdateMaxSpeed speed: String)
    func ride(manager: RideManager, didUpdateDistance distance: String)
    func ride(manager: RideManager, didUpdateCalories calories: String)
    func ride(manager: RideManager, didUpdateLocations locations: [CLLocation], distance: Double)
    func ride(manager: RideManager, didStop ride: Ride)
    func ride(manager: RideManager, didReach goal: Double, ride: Ride)
    func ride(manager: RideManager, didUpdateRideInfo infos: [RideInfo])
    func ride(manager: RideManager, didChangeState state: RideState)
}

class RideManager: NSObject {
    
    //MARK: Properties
    static var shared = RideManager()
    weak var delegate: RideManagerDelegate?
    
    var ride: Ride? {
        didSet {
            UIApplication.shared.isIdleTimerDisabled = !(ride == nil)
        }
    }
    
    //time
    static var startTime: Date?
    static var diference: Int = 0
    fileprivate var durationTimer: Timer?
    
    private var locationManager = CLLocationManager()
    private var locations: [CLLocation] = []
    private var speeds = [CLLocationSpeed]()
    private var pausedLocations: [CLLocation] = []
    private var centerPoint: CLLocation?
    
    //states
    private var isPaused: Bool = false
    var hasRideInProgress: Bool {
        return ride != nil
    }
    
    private var title: String = ""
    private var desc: String = ""
    private var rideInfos: [RideInfo] = []
    private var maxValue: Int = 0
    
    fileprivate var currentDistance: Double = 0 //meters
    fileprivate var currentCalories: Double = 0 //kcal
    fileprivate var currentSpeed: Double = 0 // m/s
    fileprivate var altitude: Int = 0 //meters
    fileprivate var coordinate: RideCoordinate = RideCoordinate()
    
    static var hasToPublishLocalNotification: Int = 1
    
    //MARK: Ride States
    func start(with mode: RideMode){
        let modesMaxValue: [RideMode] = [.time, .distance, .calories]
        if modesMaxValue.contains(mode) {
            maxValue = MainController.maxValue
        }
        //startLocationService()
        AppStoreReview.incrementAppOpenedCount()
        //dispatch { AppStoreReview.checkAndAskForReview() }
        ride = Ride.create(mode: mode, version: .v2)
        RideManager.diference = 0
        RideManager.startTime = Date()
        runTimer()
        
        if let id = ride?.id {
            MainController.rideId = id
        }
        
        guard let appOpenCount = Defaults.value(forKey: UserDefaultsIntKey.appOpenedCount) as? Int else {
            Defaults.set(1, forKey: UserDefaultsIntKey.appOpenedCount)
            return
        }
        //log
        let parameters = ["Ride_count": appOpenCount, "Ride_type": mode.rawValue] as [String : Any]
        Analytics.logEvent(appOpenCount == 1 ? "user_first_ride" : "user_starts_ride", parameters: parameters)
    }
    
    func pause(){
        isPaused = true
        durationTimer?.invalidate()
        if let startTime = RideManager.startTime {
            RideManager.diference += Int(Date().timeIntervalSince(startTime))
        }
        RideManager.startTime = nil
    }
    
    func resume(){
        isPaused = false
        RideManager.startTime = Date()
        runTimer()
    }
    
    func stop(saveRide: Bool = true){
        //locationManager.stopUpdatingLocation()
        if saveRide {
            ride?.title = title
            ride?.desc = desc
            rideInfos.forEach { info in
                ride?.rideInfos.insert(info)
            }
            guard let ride else { return }
            ride.save()
        }
        resetRide()
    }
    
    func continuesSave() {
        ride?.title = title
        ride?.desc = desc
        rideInfos.forEach { info in
            ride?.rideInfos.insert(info)
        }
        guard let ride else { return }
        ride.save()
    }
    
    func resetRide(){
        speeds = []
        locations = []
        pausedLocations = []
        rideInfos = []
        ride = nil
        isPaused = false
        RideManager.diference = 0
        RideManager.startTime = nil
        coordinate = RideCoordinate()
        altitude = 0
        currentSpeed = 0
        currentDistance = 0
        currentCalories = 0
        destroy(timer: &durationTimer)
        maxValue = 0
        MainController.maxValue = 0
        RideManager.hasToPublishLocalNotification = 1
    }
    
    
    //MARK: Timer
    func runTimer() {
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [self] timer in
            var duration = 0
            if let startTime = RideManager.startTime {
                duration = Int(Date().timeIntervalSince(startTime)) + RideManager.diference
            }
            let time = Utils.secondsToHoursMinutesSeconds(seconds: duration)
            delegate?.ride(manager: self, didUpdateTime: time, seconds: duration)
            
            guard !isPaused else { return }
            let info = RideInfo.create(time: duration, date: Date(), distance: currentDistance, speed: currentSpeed, calories: Int(self.currentCalories), altitude: altitude, coordinates: coordinate)
            info.rideId = ride?.id ?? ""
            rideInfos.append(info)
            delegate?.ride(manager: self, didUpdateRideInfo: rideInfos)
            
            //print("LAT: \(self.coordinate.coordinate.latitude) - LONG: \(self.coordinate.coordinate.longitude)")
            //print("-------")
            
            sendNotifications(duration: duration)
        })
    }
    
    func destroy(timer: inout Timer?){
        timer?.invalidate()
        timer = nil
    }
    
    
    //MARK: Computate/Update Ride
    fileprivate func computateRide(infoPoint: CLLocation) {
        let (calculatedSpeed, duration) = RideCalculations.getIntervalSpeedAndTime(locations: self.locations)
        var ms = infoPoint.speed > 0 ? infoPoint.speed : calculatedSpeed
        ms = ((0.01...Constants.minSpeedValue).contains(ms) || ms < 0) ? 0 : ms
        let (speed, progress) = Utils.mpsToSpeed(ms: ms)
        
        setRideMetrics(infoPoint: infoPoint, ms: ms, duration: duration)
        sendRideDelegates(ms: ms, speed: speed, progress: progress)
    }
    
    func getDistance() {
        if locations.count == 1 { centerPoint = locations.first }
        
        guard let centerPoint, let lastLocation = locations.last else { return }
        let distance = lastLocation.distance(from: centerPoint)
        if distance > abs(centerPoint.horizontalAccuracy) + abs(centerPoint.verticalAccuracy) + abs(lastLocation.horizontalAccuracy) + abs(lastLocation.verticalAccuracy) {
            self.centerPoint = lastLocation
            currentDistance += distance
        }
    }
    
    private func setRideMetrics(infoPoint: CLLocation, ms: CLLocationSpeed, duration: Double) {
        //Get Speed
        currentSpeed = ms
        speeds.append(ms)
        
        //Get Distance
        getDistance()
        
        //Get Calories
        currentCalories += Utils.calculateCalories(speed: ms, duration: duration, slope: RideCalculations.getSlope(locations: locations), altitude: altitude)
        
        //Get Coordinates
        coordinate.latitude = infoPoint.coordinate.latitude
        coordinate.longitude = infoPoint.coordinate.longitude
        
        //Get Altitude
        altitude = Int(infoPoint.altitude)
    }
    
    fileprivate func sendRideDelegates(ms: CLLocationSpeed, speed: String, progress: Double ) {
        delegate?.ride(manager: self, didUpdateSpeed: speed, progressPercentage: progress)
        delegate?.ride(manager: self, didUpdateAverageSpeed: Utils.averageSpeed(speeds: speeds))
        delegate?.ride(manager: self, didUpdateMaxSpeed: Utils.maxSpeed(from: speeds))
        delegate?.ride(manager: self, didUpdateCalories: String(Int(currentCalories)))
        delegate?.ride(manager: self, didUpdateLocations: locations, distance: currentDistance)
    }
    
    func updateSpeedDelegateOnly(_ speed: CLLocationSpeed) {
        let (speed, progress) = Utils.mpsToSpeed(ms: speed)
        delegate?.ride(manager: self, didUpdateSpeed: speed, progressPercentage: progress)
    }
    
    //MARK: Notifications
    private func sendNotifications(duration: Int) {
        guard RideManager.hasToPublishLocalNotification == 1 else { return }
        
        //duration is in seconds, maxValue is in minutes
        if let ride, ride.mode == .time, duration >= maxValue * 60 {
            PushNotificationManager.sendNotification(mode: ride.mode, value: 1)
            RideManager.hasToPublishLocalNotification = 2
        }
        
        if let ride, ride.mode == .distance, Int(currentDistance) >= maxValue {
            PushNotificationManager.sendNotification(mode: ride.mode, value: 1)
            RideManager.hasToPublishLocalNotification = 2
        }
        
        if let ride, ride.mode == .calories, Int(currentCalories) >= self.maxValue {
            PushNotificationManager.sendNotification(mode: ride.mode, value: 1)
            RideManager.hasToPublishLocalNotification = 2
        }
    }
}

//MARK: LocationManager Delegates
extension RideManager: CLLocationManagerDelegate {
    func startLocationService() {
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        checkLocationAuthorization()
    }
    
    fileprivate func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse, .restricted, .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        console("Error to get location : \(error) ")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard hasRideInProgress else {
            guard let uL = locations.last, uL.horizontalAccuracy < 15 else {
                updateSpeedDelegateOnly(0)
                return
            }
            console("Coordinate Accuracy: H(\(uL.horizontalAccuracy))")
            updateSpeedDelegateOnly(uL.speed)
            return
        }
        
        if !isPaused {
            //guard locations.count > 0, let uL = locations.last, uL.horizontalAccuracy < 10 else { return }
            guard let uL = locations.last, uL.horizontalAccuracy < 15 else {
                updateSpeedDelegateOnly(0)
                return
            }
            console("Ride Accuracy: H(\(uL.horizontalAccuracy))")
            LocationManager.shared.lastLocation = uL
            self.locations.append(uL)
            computateRide(infoPoint: uL)
        } else {
            guard let lastLocation = locations.last, lastLocation.horizontalAccuracy < 15 else { return }
            pausedLocations.append(lastLocation)
            
            if RideCalculations.getPausedDistance(pausedLocations: pausedLocations) > 0 {
                delegate?.ride(manager: self, didChangeState: .continuing)
                pausedLocations = []
            }
        }
    }
}

class AccountManager: NSObject {
    static func handleSubscriptionWith(status: Bool) {
        Preferences.isProUser = status
        NotificationCenter.default.post(name: .userProChanged, object: nil)
    }
}
