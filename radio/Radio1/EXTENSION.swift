//
//  EXTENSION.swift
//  Radio1
//
//  Created by ismmajl on 09/08/2019.
//  Copyright © 2019 Radio1. All rights reserved.
//

import UIKit
import WebKit

//MARK: - UI
@IBDesignable extension UIView {
    @IBInspectable var borderColor:UIColor? {
        set {
            layer.borderColor = newValue!.cgColor
        }
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor:color)
            }
            else {
                return nil
            }
        }
    }
    @IBInspectable var borderWidth:CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    @IBInspectable var cornerRadius:CGFloat {
        set {
            layer.cornerRadius = newValue
            clipsToBounds = newValue > 0
        }
        get {
            return layer.cornerRadius
        }
    }
}
public enum DayOfWeek: Int {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday
    
    var distance: Int {
        switch self {
        case .monday: return 1
        case .tuesday: return 2
        case .wednesday: return 3
        case .thursday: return 4
        case .friday: return 5
        case .saturday: return 6
        case .sunday: return 7
        }
    }
    
    static func create(string: String) -> DayOfWeek {
        switch string {
            case "Mon": return .monday
            case "Tue": return .tuesday
            case "Wed": return .wednesday
            case "Thu": return .thursday
            case "Fri": return .friday
            case "Sat": return .saturday
            case "Sun": return .sunday
            default: return .monday
        }
    }
}
extension Date {
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    static func getCurrentWeekDays(firstDayOfWeek: DayOfWeek? = nil) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = (firstDayOfWeek ?? .Sunday).rawValue
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        let weekdays = calendar.range(of: .weekday, in: .weekOfYear, for: today)!
        let days = (weekdays.lowerBound ..< weekdays.upperBound).compactMap { calendar.date(byAdding: .day, value: $0 - dayOfWeek, to: today) }
        return days
    }
    
    func add(component: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: component, value: value, to: self)!
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        return self.set(hour: 23, minute: 59, second: 59)
    }
    
    func getDayOfWeek() -> DayOfWeek {
        let dayName = Date().weekdayName(.short)
        let weekDay = DayOfWeek.create(string: dayName)
        return weekDay
    }
    
    func getTimeIgnoreSecondsFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    static func daysBetween(start: Date, end: Date, ignoreHours: Bool) -> Int {
        let startDate = ignoreHours ? start.startOfDay : start
        let endDate = ignoreHours ? end.startOfDay : end
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day!
    }
    
    static let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second, .weekday]
    private var dateComponents: DateComponents {
        return  Calendar.current.dateComponents(Date.components, from: self)
    }
    
    var year: Int { return dateComponents.year! }
    var month: Int    { return dateComponents.month! }
    var day: Int { return dateComponents.day! }
    var hour: Int { return dateComponents.hour! }
    var minute: Int    { return dateComponents.minute! }
    var second: Int    { return dateComponents.second! }
    
    var weekday: Int { return dateComponents.weekday! }
    
    func set(year: Int?=nil, month: Int?=nil, day: Int?=nil, hour: Int?=nil, minute: Int?=nil, second: Int?=nil, tz: String?=nil) -> Date {
        let timeZone = Calendar.current.timeZone
        let year = year ?? self.year
        let month = month ?? self.month
        let day = day ?? self.day
        let hour = hour ?? self.hour
        let minute = minute ?? self.minute
        let second = second ?? self.second
        let dateComponents = DateComponents(timeZone:timeZone, year:year, month:month, day:day, hour:hour, minute:minute, second:second)
        let date = Calendar.current.date(from: dateComponents)
        return date!
    }
}
extension Date {
    func dayNumberOfWeek() -> Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }
}
extension UITableView {
    func register<T: UITableViewCell>(_: T.Type, reuseIdentifier: String? = nil) {
        let nib = UINib(nibName: reuseIdentifier ?? String(describing: T.self), bundle: nil)
        self.register(nib, forCellReuseIdentifier: reuseIdentifier ?? String(describing: T.self))
    }
    
    func dequeue<T: UITableViewCell>(_: T.Type, for indexPath: IndexPath, reuseIdentifier: String? = nil) -> T {
        guard
            let cell = dequeueReusableCell(withIdentifier: reuseIdentifier ?? String(describing: T.self),
                                           for: indexPath) as? T
            else { fatalError("Could not deque cell with type \(T.self)") }
        
        return cell
    }
}
extension Date {
    func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        return date1.compare(self) == self.compare(date2)
    }
}
extension UIScrollView {
    var currentPage:Int{
        return Int((self.contentOffset.x + (0.5 * self.frame.size.width)) / self.frame.width)
    }
}

extension Date {
    var startOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 1, to: sunday)
    }
}

extension UIViewController {
    static func create(controller: String, storyboardName: String) -> UIViewController? {
        return UIStoryboard(name: storyboardName, bundle: nil).instantiateViewController(withIdentifier: controller)
    }
}
extension UIStoryboard {
    func instantiate<T: UIViewController>(_ : T.Type, identifier: String? = nil) -> T {
        return self.instantiateViewController(withIdentifier: identifier ?? String(describing: T.self)) as! T
    }
    static var main: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
}
