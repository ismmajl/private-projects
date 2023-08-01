//
//  Bird.swift
//  upbike

import UIKit

enum Tweet: String {
    case main
    case rideDetails
}

class Bird: NSObject {

    static func tweet(name: Tweet, object: Any? = nil) {
        NotificationCenter.default.post(name: NSNotification.Name.init(name.rawValue), object: object)
    }
    
    static func listen(observer: Any, name: Tweet, selector: Selector, object: Any? = nil) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: name.rawValue), object: object)
    }
    
    static func removeTweet(observer: Any, name: Tweet, object: Any? = nil) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: name.rawValue), object: object)
    }
    
    //remove all observers
    static func sleep() {
        NotificationCenter.default.removeObserver(self)
    }
}
