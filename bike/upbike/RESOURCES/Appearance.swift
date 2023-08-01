//
//  Appearance.swift
//  combike

import UIKit

class Appearance: NSObject {

    static func regularFont(size: CGFloat = 16) -> UIFont {
        guard let font = UIFont(name: "Campton-Book", size: size) else { return UIFont.systemFont(ofSize: size) }
        return font
    }
    static func mediumFont(size: CGFloat = 16) -> UIFont {
        guard let font = UIFont(name: "Campton-Medium", size: size) else { return UIFont.systemFont(ofSize: size) }
        return font
    }
    static func semiBoldFont(size: CGFloat = 16) -> UIFont {
        guard let font = UIFont(name: "Campton-SemiBold", size: size) else { return UIFont.systemFont(ofSize: size) }
        return font
    }
    static func boldFont(size: CGFloat = 16) -> UIFont {
        guard let font = UIFont(name: "Campton-Bold", size: size) else { return UIFont.systemFont(ofSize: size) }
        return font
    }

    static func setup() {
        let nav = UINavigationBar.appearance()
        //nav.barStyle = .default
        nav.isTranslucent = false
        nav.barTintColor = UIColor.TintColor
        nav.tintColor = .WhiteBlackColor
        //remove nav line
        nav.shadowImage = UIImage()
        nav.backIndicatorImage                  = .backIcon
        nav.backIndicatorTransitionMaskImage    = .backIcon
        nav.titleTextAttributes = [.font: boldFont(size: 18), .foregroundColor: UIColor.WhiteBlackColor]
        
        if #available(iOS 13, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor              = UIColor.TintColor
            appearance.shadowColor                  = UIColor.TintColor
            appearance.titleTextAttributes          = [.foregroundColor: UIColor.WhiteBlackColor, .font: boldFont(size: 18)]
            appearance.setBackIndicatorImage(.backIcon, transitionMaskImage: .backIcon)

            UINavigationBar().standardAppearance    = appearance
            nav.scrollEdgeAppearance                = appearance
            nav.standardAppearance                  = appearance
        }
        
        UITabBar.appearance().layer.borderWidth = 0.0
        UITabBar.appearance().clipsToBounds = true
        
        let barAppearance = UIBarButtonItem.appearance()
        barAppearance.setBackButtonTitlePositionAdjustment(UIOffset(horizontal: 0, vertical: 0), for:UIBarMetrics.default)
        barAppearance.setTitleTextAttributes([.font: mediumFont(size: 15)], for: .normal)
    }
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}

class TableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}

class CollectionViewController: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}
