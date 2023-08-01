//
//  Alerter.swift
//  upbike

import Foundation
import UIKit

class Alerter {
    
    static func show(controller: UIViewController, title: String = "General.action.Notification".localized(), message: String, completion: ((UIAlertAction)->Void)? = nil ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.setTitlet(font: Appearance.mediumFont(size: 20), color: .BlackColor)
        alert.setBackgroundColor(color: .WhiteColor)
        alert.view.tintColor = .TintColor
        Haptic.shared.impact(haptic: .warning)
        alert.addAction(UIAlertAction(title: "General.action.Cancel".localized(), style: .cancel, handler: nil))

        alert.setTint(color: .TintColor)
        controller.present(alert, animated: true, completion: nil)
    }
    
    static func notification(controller: UIViewController, title: String = "General.action.Warning".localized(), message: String, completion: ((UIAlertAction)->Void)? = nil, cancelCompletion: ((UIAlertAction)->Void)? = nil ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.view.tintColor = .TintColor
        alert.addAction(UIAlertAction(title: "General.action.Yes".localized(), style: .default, handler: completion))
        alert.addAction(UIAlertAction(title: "General.action.No".localized(), style: .cancel, handler: cancelCompletion))
        alert.view.tintColor = .TintColor
        controller.present(alert, animated: true, completion: nil)
        alert.view.tintColor = .TintColor
    }
}


enum HapticCase {
    case success
    case warning
    case error
    case none
}

class Haptic: NSObject {
    
    static var shared = Haptic()
    
    func impact(haptic: HapticCase) {
        let generator = UINotificationFeedbackGenerator()
        //guard Preferences.allowVibrate else { return }
        switch haptic {
        case .success:  generator.notificationOccurred(.success)
        case .warning:  generator.notificationOccurred(.warning)
        case .error:    generator.notificationOccurred(.error)
        case .none:     break
        }
    }
}
