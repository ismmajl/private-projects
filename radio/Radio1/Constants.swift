//
//  Constants.swift
//  Radio1
//
//  Created by ismmajl on 09/08/2019.
//  Copyright © 2019 Radio1. All rights reserved.
//

import Foundation
import SafariServices
import UIKit

class Help: NSObject {
    static func openWeb(page address: String?){
        if var web = address {
            if !web.contains("http"){
                web = "http://" + web
            }
            guard let url = URL(string: web) else { return }
            let safariController = SFSafariViewController(url: url)
            safariController.modalPresentationStyle = .formSheet
            
            if #available(iOS 10.0, *) {
                safariController.preferredBarTintColor = .black
                safariController.preferredControlTintColor = UIColor.white
                safariController.navigationController?.navigationBar.titleTextAttributes = [ NSAttributedString.Key.foregroundColor: UIColor.white]
            }
            UIApplication.topViewController()?.present(safariController, animated: true, completion: nil)
        }
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

struct Preferences {
    static var streamUrl: String {
        get {
            return UserDefaults.standard.string(forKey: "resourcePath") ?? Constants.streamUrl
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "resourcePath")
        }
    }
}
