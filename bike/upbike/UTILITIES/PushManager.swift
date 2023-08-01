//
//  PushManager.swift
//  combike

import UIKit
import UserNotifications

enum RideMessageType {
    case rideInProgress, rideGoalReached
    
    var name: String {
        switch self {
        case .rideInProgress:
            return "RideMessageType.label.RideInProgress".localized()
        case .rideGoalReached:
            return "RideMessageType.label.RideGoalReached".localized()
        }
    }
}

class PushNotificationManager: NSObject {
    static func registerForPushNotifications() {
        #if targetEnvironment(simulator)
            return //this is simulator baby
        #endif
        
        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in
            if granted {
                dispatch { UIApplication.shared.registerForRemoteNotifications() }
                UIApplication.shared.beginBackgroundTask(withName: "showNotification", expirationHandler: nil)
            }
        }
    }
    
    static func sendNotificationWhenApplicationEnterBackground() {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Combike"
        notificationContent.body = "RideMessageType.label.RideInProgress".localized()
        notificationContent.badge = NSNumber(value: 1)
        notificationContent.sound = UNNotificationSound.defaultCritical
        
        if let url = Bundle.main.url(forResource: "dune", withExtension: "png") {
            if let attachment = try? UNNotificationAttachment(identifier: "dune",  url: url, options: nil) {
                notificationContent.attachments = [attachment]
            }
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,  repeats: false)
        let request = UNNotificationRequest(identifier: "showTimeNotification", content: notificationContent, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error {
                print("Notification Error: ", error)
            }
        }
    }

    static func sendNotification(mode: RideMode, value: Int) {
        guard value > 0 else { return }
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Combike"
        notificationContent.body = "RideMessageType.label.RideGoalReached".localized()
        notificationContent.badge = NSNumber(value: 1)
        notificationContent.sound = UNNotificationSound.defaultCritical
        
        if let url = Bundle.main.url(forResource: "dune", withExtension: "png") {
            if let attachment = try? UNNotificationAttachment(identifier: "dune",  url: url, options: nil) {
                notificationContent.attachments = [attachment]
            }
        }
        
        switch mode {
            case .free: break
            
            case .calories:
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,  repeats: false)
                let request = UNNotificationRequest(identifier: "showCaloriesNotification", content: notificationContent, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { (error) in
                    if let error {
                        print("Notification Error: ", error)
                    }
                }
            
            case .distance:
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,  repeats: false)
                let request = UNNotificationRequest(identifier: "showDistanceNotification", content: notificationContent, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { (error) in
                    if let error {
                        print("Notification Error: ", error)
                    }
                }
            
            case .time:
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,  repeats: false)
                let request = UNNotificationRequest(identifier: "showTimeNotification", content: notificationContent, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { (error) in
                    if let error {
                        print("Notification Error: ", error)
                    }
                }
        }
    }
    
    static func removeAllLocalNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
