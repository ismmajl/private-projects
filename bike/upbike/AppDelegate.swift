//
//  AppDelegate.swift
//  combike

import UIKit
import UserNotifications
import GoogleMobileAds
import SwiftyStoreKit
import Firebase
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    var locationManager = CLLocationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        Appearance.setup()
        setRootWindow()
        purchareStarter()
        PaymentManager.checkForSubscriptions()
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        LanguageManager.setSystemsLanguage()
        UNUserNotificationCenter.current().delegate = self
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization( options: authOptions, completionHandler: {_, _ in })
        application.registerForRemoteNotifications()
        
        if !Preferences.hasSetAutoPause {
            Preferences.autoPause = 60
            Preferences.hasSetAutoPause = true
        }
        
        locationManager.delegate = self
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        if let ride = RideManager.shared.ride {
            print(ride)
            PushNotificationManager.sendNotificationWhenApplicationEnterBackground()
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        //
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: NSNotification.Name.applicationForeground, object: nil)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if Preferences.hasSeenIntro { locationManagerDidChangeAuthorization(locationManager) }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        PushNotificationManager.removeAllLocalNotifications()
    }
    
    fileprivate func purchareStarter(){
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break
                }
            }
        }
    }
    
    func setRootWindow(){
        switchWindowRoot(to: Preferences.hasSeenIntro ? .main : .intro)
        if Preferences.hasSeenIntro { locationManagerDidChangeAuthorization(locationManager) }
    }
    
    fileprivate func switchWindowRoot(to place: ApplicationPlace){
        switch place {
        case .main:
            let controller = UIStoryboard.main.instantiateInitialViewController()!
            self.window?.set(root: controller)
            break
            
        case .intro:
            let controller = UIStoryboard.introduction.instantiateInitialViewController()!
            self.window?.set(root: controller)
            break
        }
    }
    
    enum ApplicationPlace {
        case main
        case intro
    }
}

extension NSNotification.Name {
    public static let applicationForeground = NSNotification.Name.init("ApplicationForeground")
    public static let ridesChanged = NSNotification.Name.init("ridesChanged")
    public static let modeChanged = NSNotification.Name.init("modeChanged")
    public static let userProChanged = NSNotification.Name.init("userProChanged")
}

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        guard let fcmToken = fcmToken else { return }
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        LocationManagerHelper.checkLocationAtStart(manager: manager)
    }
}
