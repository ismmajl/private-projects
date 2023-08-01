//
//  AppStoreReview.swift
//  combike

import Foundation
import StoreKit

let Defaults = UserDefaults.standard

struct AppStoreReview {
    static func incrementAppOpenedCount() {
        guard var appOpenCount = Defaults.value(forKey: UserDefaultsIntKey.appOpenedCount ) as? Int else {
            Defaults.set(1, forKey: UserDefaultsIntKey.appOpenedCount)
            return
        }
        appOpenCount += 1
        Defaults.set(appOpenCount, forKey: UserDefaultsIntKey.appOpenedCount)
        
        if appOpenCount % 3 == 1 && appOpenCount != 1 {
            Preferences.showReview = true
        }
    }
    static func checkAndAskForReview() {
        guard let appOpenCount = Defaults.value(forKey: UserDefaultsIntKey.appOpenedCount) as? Int else {
            Defaults.set(1, forKey: UserDefaultsIntKey.appOpenedCount)
            return
        }
        
        switch appOpenCount {
        case _ where appOpenCount % 3 == 1 && appOpenCount != 1:
            dispatch {
                AppStoreReview.requestReview()
            }
        default:
            console("App run count is : \(appOpenCount)")
            break;
        }
        
    }
    static func requestReview() {
        SKStoreReviewController.requestReview()
    }
    
    static func requestWriteReview() {
        guard let productURL = URL(string: "https://itunes.apple.com/app/" + Constants.appId) else { return }
        var components = URLComponents(url: productURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [ URLQueryItem(name: "action", value: "write-review") ]
        guard let writeReviewURL = components?.url else { return }
        UIApplication.shared.open(writeReviewURL)
    }
}

struct UserDefaultsIntKey {
    static let appOpenedCount = "appOpenedCount"
}
