//
//  AccountManager.swift
//  luuria

import UIKit
import SwiftKeychainWrapper
import RealmSwift
import Kingfisher
import UserNotifications

typealias UserToken = String

class AccountManager: NSObject {
    static var currentUser: User?
    
    static var userId: Int {
        get {
            if let id = KeychainWrapper.standard.integer(forKey: "UserId"){
                return id
            }else{
                return 0
            }
        }
        set {
            KeychainWrapper.standard.set(newValue, forKey: "UserId")
        }
    }
    
    static var userToken: String? {
        get {
            return KeychainWrapper.standard.string(forKey: "UserToken")
        }
        set {
            KeychainWrapper.standard.set(newValue ?? "", forKey: "UserToken")
        }
    }
    
    
    static var isLogged: Bool {
        
        guard let token = userToken else {
            return false
        }
        
        if token.isEmpty {
            return false
        }
        
        if currentUser == nil {
            return false
        }
        
        if userId == 0 {
            return false
        }
        
        return true
    }
    
    static func start() {
        let uid = self.userId
        
        let user = User.find(uid)?.toObject()
        AccountManager.currentUser = user
    }
    
    static func start(user: User, token: UserToken) {
        currentUser = user
        userToken = token
        userId = user.id
        
        user.save()
    }
    
    static func delete() {
        
        Preferences.userPushNotificationsEnabled = true
        PushNotificationManager.unregister()
        
        
        AccountManager.currentUser?.delete()
        
        userId = 0
        currentUser = nil
        userToken = nil
        
        //  OfflineFileManager.deleteAll()
        // ImageCache.default.clearDiskCache()
        // ImageCache.default.clearMemoryCache()
        
        //DELETE USER FILES
        Wallet.deleteAll()
        Card.deleteAll()
        Address.deleteAll()
        PayPal.deleteAll()
        Country.deleteAll()
        City.deleteAll()
        Region.deleteAll()
        Conversation.deleteAll()
        ConversationMessage.deleteAll()
        Message.deleteAll()
//        Prefix.deleteAll()
        Review.deleteAll()
    }
    
    static func updateProfile(completion: ((Bool) -> Void)? = nil) {
        UserREST.getMyProfile { (user, error) in
            if let user = user {
                AccountManager.currentUser = user
                AccountManager.currentUser?.save()
                completion?(true)
            }
            
            if let error = error {
                print(error.message)
                completion?(false)
            }
        }
    }
    
    class func updateRootWindow(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.setRootWindow()
    }
}
