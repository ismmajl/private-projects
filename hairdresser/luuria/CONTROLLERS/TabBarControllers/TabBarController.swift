//
//  TabBarController.swift
//  luuria

import UIKit
import DeviceKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    open var discover : DiscoverController!
    open var bookings : BookingController!
    open var chat: MessagesController!
    open var favorite : FavoriteController!
    open var profile : ProfileController!
    
    static var shared: TabBarController!
//    let titlesTabbar  = ["SEARCH".localized, "BOOKINGS".localized(), "CHAT".localized, "FAVORITES".localized, "PROFILE".localized]
    let titlesTabbar  = ["SEARCH".localized, "BOOKINGS".localized(), "CHAT".localized, "PROFILE".localized]


    override func viewDidLoad() {
        super.viewDidLoad()
        
        findChildControllers()
        self.delegate = self
        tabBarImages()
        var height : CGFloat = 0.0
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2436: // print("iPhone X")
                height = CGFloat(tabBar.frame.height - 1)
            default:
                height = CGFloat(tabBar.frame.height)
            }
        }
        ResourcesManager.readFromCache()
        ResourcesManager.refresh()
        ResourcesManager.start()
        registerNotification(notification: .OpenConversation, selector: #selector(handleMessageUser))
        registerNotification(notification: .newNotifications, selector: #selector(newNotifications))

        //let tabBar = tabBarController!.tabBar
//        tabBar.selectionIndicatorImage = UIImage().createSelectionIndicator(color: Appearance.toupe, size: CGSize(width: tabBar.frame.width/CGFloat(tabBar.items!.count), height: height), lineWidth: 3.0) //adding the bottom line on activ
        
        if Preferences.userPushNotificationsEnabled {
            PushNotificationManager.registerForPushNotifications()
        }
        TabBarController.shared = self
    }
    func tabBarImages(){
        let arrayOfImageNameForSelectedState = ["TAB ICON 1 SELECTED","TAB ICON 2 SELECTED","TAB ICON 3 SELECTED","TAB ICON 5 SELECTED"]
        let arrayOfImageNameForDeSelectedState = ["TAB ICON 1 UNSELECTED","TAB ICON 2 UNSELECTED","TAB ICON 3 UNSELECTED","TAB ICON 5 UNSELECTED"]
        if let items = self.tabBar.items {
            for i in 0...(items.count-1) {
                let imageNameForSelectedState   = arrayOfImageNameForSelectedState[i]
                let imageNameForUnselectedState = arrayOfImageNameForDeSelectedState[i]
                let item = items[i]
                item.selectedImage = UIImage(named: imageNameForSelectedState)?.withRenderingMode(.alwaysOriginal)
                item.image = UIImage(named: imageNameForUnselectedState)?.withRenderingMode(.alwaysOriginal)
                item.title = self.tabBar.items?[i].title
                if Device.allXSeriesDevices.contains(Device.current){
                    item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)
                    item.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
                }
            }
        }
    }
    @objc func handleMessageUser(notification: Notification) {
        guard let employee = notification.object as? Employee else { return }
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        if let chatController = UIApplication.topViewController() as? ChatController {
            chatController.switchTo(Conversation.create(provider: employee))
        }else {
            delegate.window?.rootViewController?.dismiss(animated: false, completion: {
                let controller = ChatController.create(conversation: Conversation.create(provider: employee))
                self.push(controller)
            })
        }
    }
    private func findChildControllers() {
        for child in viewControllers! {
            if child is UINavigationController {
                if let controller = (child as! UINavigationController).viewControllers.first {
                    switch controller {
                        
                    case is DiscoverController:
                        discover = (controller as! DiscoverController)
                        break
                        
                    case is BookingController:
                        bookings = (controller as! BookingController)
                        break
                        
                    case is MessagesController:
                        chat = (controller as! MessagesController)
                        
                    case is FavoriteController:
                        favorite = (controller as! FavoriteController)
                        break
                        
                    case is ProfileController:
                        profile = (controller as! ProfileController)
                        break
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
//        if let index = tabBar.items?.indexes(of: item).first{
//            animateTabItemAt(index: index)
//        }
    }
    
    func animateTabItemAt(index: Int, isDirectTouch: Bool = true) {
        
        let list = orderedTabBarItemViews()
        for item in list{
            let i = list.indexes(of: item).first!
            
            if let label = item.subviews.last{
                if i == index{
                    UIView.animate(withDuration: 0.2) {
                        label.frame.origin.y = 35
                    }
                }else{
                    UIView.animate(withDuration: 0.2) {
                        label.frame.origin.y = 100
                    }
                }
            }
        }
    }
    @objc func newNotifications(notification: Notification){
        guard let new = notification.object as? Bool else { return }
        if new {
            addRedDotAtTabBarItemIndex(index: 3)
        } else {
            removeRedDotAtTabBarItemIndex()
        }
    }
    func updateProfileBadge() {
        let unread = UserNotifications.shared.getUnReadNotificationCount()
        let badgeActive = unread > 0
        if badgeActive {
            addRedDotAtTabBarItemIndex(index: 3)
        } else {
            removeRedDotAtTabBarItemIndex()
        }
    }
    func addRedDotAtTabBarItemIndex(index: Int) {
        removeRedDotAtTabBarItemIndex()
        
        let redDotRadius: CGFloat = 5
        let redDotDiameter = redDotRadius * 2
        
        let topMargin: CGFloat = 12
        
        let tabBarItemCount = CGFloat(tabBar.items!.count)
        
        let halfItemWidth = view.bounds.width / (tabBarItemCount * 2)
        
        let xOffset = halfItemWidth * CGFloat(index * 2 + 1)
        
        let imageHalfWidth: CGFloat = (tabBar.items![index]).selectedImage!.size.width / 4
        
        let redDot = UIView(frame: CGRect(x: xOffset + imageHalfWidth, y: topMargin, width: redDotDiameter, height: redDotDiameter))
        
        redDot.tag = 1314
        redDot.backgroundColor = Appearance.newDark
        redDot.layer.cornerRadius = redDotRadius
        
        tabBar.addSubview(redDot)
    }
    
    func removeRedDotAtTabBarItemIndex(){
        for subview in tabBar.subviews {
            
            if let subview = subview as? UIView {
                if subview.tag == 1314 {
                    subview.removeFromSuperview()
                    break
                }
            }
        }
    }
    
    func getTabBarButtonAt(_ index: Int) -> UIView?{
        let tabbarViews = orderedTabBarItemViews()
        if let vv = tabbarViews.item(at: index){
            return vv
        }
        return nil
    }
    
    func orderedTabBarItemViews() -> [UIView] {
        let interactionViews = tabBar.subviews.filter({$0.isUserInteractionEnabled})
        return interactionViews.sorted(by: {$0.frame.minX < $1.frame.minX})
    }
}


extension UIImage {
    class func colorForNavBar(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
