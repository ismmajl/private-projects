//
//  LocationManager.swift
//  combike

import Foundation
import UIKit
import CoreLocation

//MARK: - LOCATION
class LocationManager: NSObject {
    static let shared = LocationManager()
    var lastLocation: CLLocation?
}

class LocationManagerHelper {
    
    static func checkLocationAtStart(manager: CLLocationManager) {
        guard Preferences.hasSeenIntro else { return }
        let nav = UINavigationController(rootViewController: EnableLocationController.create())
        nav.modalPresentationStyle = .fullScreen
        
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus {
            case .authorizedAlways , .authorizedWhenInUse:
                guard let controller = UIApplication.topViewController(), controller.isKind(of: EnableLocationController.self) else { return }
                controller.hideModal()
            case .notDetermined , .denied , .restricted:
                let controller = MainController()
                controller.showModal(nav)
            default:
                let controller = MainController()
                controller.showModal(nav)
            }
        } else {
            //old version
            guard CLLocationManager.locationServicesEnabled() else {
                let controller = MainController()
                controller.showModal(nav)
                return
            }
            
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                guard let controller = UIApplication.topViewController(), controller.isKind(of: EnableLocationController.self) else { return }
                controller.hideModal()
            default:
                let controller = MainController()
                controller.showModal(nav)
            }
        }
        
        /*
        switch manager.accuracyAuthorization {
        case .fullAccuracy, .reducedAccuracy:
            break
        default:
            break
        }
        */
    }
    
    
    static func checkLocation(manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus {
            case .authorizedAlways , .authorizedWhenInUse:
                Preferences.isLocationEnabled = true
                
            case .notDetermined , .denied , .restricted:
                Preferences.isLocationEnabled = false
                requestPermission(locationManager: manager)
                
            @unknown default:
                Preferences.isLocationEnabled = false
            }
        } else {
            //old version
            guard CLLocationManager.locationServicesEnabled() else {
                Preferences.isLocationEnabled = false
                return
            }
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                Preferences.isLocationEnabled = true
                
            case .notDetermined, .restricted, .denied:
                Preferences.isLocationEnabled = false
                requestPermission(locationManager: manager)
                
            @unknown default:
                break
            }
        }
    }
    
    private static func requestPermission(locationManager: CLLocationManager) {
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
}
