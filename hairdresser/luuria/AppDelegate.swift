//
//  AppDelegate.swift
//  luuria

import UIKit
import IQKeyboardManagerSwift
import Firebase
import FirebaseCore
import GoogleMaps
import UserNotifications
import SwiftyJSON
import FBSDKLoginKit
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    fileprivate var googleAPIKey = SocialAPI.GOOGLE_MAP_KEY

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Appearance.setup()
        AccountManager.start()
        setRootWindow()
        setupIQKeyoboardManager()
        GMSServices.provideAPIKey(googleAPIKey)
        UNUserNotificationCenter.current().delegate = self

        FirebaseApp.configure()
        UITextField.appearance().tintColor = Appearance.newDark
        
        PayPalMobile .initializeWithClientIds(forEnvironments: [PayPalEnvironmentProduction: SocialAPI.PAYPAL_CLIENT_ID_LIVE, PayPalEnvironmentSandbox: SocialAPI.PAYPAL_CLIENT_ID_SANDBOX, PayPalEnvironmentNoNetwork: SocialAPI.PAYPAL_CLIENT_ID_SANDBOX])
        PayPalMobile.preconnect(withEnvironment: "sandbox")

        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        return true
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationManager.didRegister(with: deviceToken)
    }
    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        if application.applicationState != .active {
//            PushNotificationManager.handleNotification(userInfo: userInfo, for: UIApplication.shared.applicationState)
//        }
//        completionHandler(.noData)
//    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if ApplicationDelegate.shared.application(app, open: url, options: options) {
            return true
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Preferences.appBadge = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    fileprivate func setupIQKeyoboardManager(){
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 110.0
        IQKeyboardManager.shared.shouldShowToolbarPlaceholder = false
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
    }
    func setRootWindow() {
        if AccountManager.isLogged {
            switchWindowRoot(to: isGetStartedShown() ? .tabBar : .intro)
        }else{
            switchWindowRoot(to: isGetStartedShown() ? .register : .intro)
        }
    }
    fileprivate func isGetStartedShown() -> Bool{
        let value = UserDefaultsKey.hasShownIntroBefore.bool ?? false
        UserDefaultsKey.hasShownIntroBefore.set(true)
        return value
    }
    fileprivate func checkForFirstRun(){
        let hasRunBefore = UserDefaultsKey.hasRunBefore.bool ?? false
        
        guard hasRunBefore == false else { return }
        
        AccountManager.delete()
        UserDefaultsKey.hasRunBefore.set(true)
    }
    
    fileprivate func switchWindowRoot(to place: ApplicationPlace){
        switch place {
            
        case .register:
            let controller = UIStoryboard.register.instantiateInitialViewController()!
            self.window?.set(root: controller)
            break
            
        case .tabBar:
            let controller = UIStoryboard.tabBar.instantiateInitialViewController()!
            self.window?.set(root: controller)
            break
            
        case .intro:
            let controller = UIStoryboard.getStarted.instantiateInitialViewController()!
            self.window?.set(root: controller)
            break
        }
    }
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void) {
        //Handle the notification
        let userInfo = notification.request.content.userInfo
        let json = JSON(userInfo)
        let jsonData = JSON.init(parseJSON: json["data"].string ?? "")
        if let conversationId = jsonData["conversation_id"].int, let conversation = ConversationMessage.create(json: jsonData, conversationId: conversationId) {
            if let chatController = UIApplication.topViewController() as? ChatController {
                if chatController.activeConversation.id == conversation.conversationId {
                    completionHandler([])
                    return
                }
            }
        }
        
        completionHandler([.alert, .sound, .badge])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        PushNotificationManager.handleNotification(userInfo: userInfo, for: UIApplication.shared.applicationState)
        completionHandler()
    }
}
