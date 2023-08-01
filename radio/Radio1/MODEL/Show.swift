//
//  Show.swift
//  Radio1
//
//  Created by ismmajl on 12/08/2019.
//  Copyright © 2019 Radio1. All rights reserved.
//

import UIKit
import SwiftDate

class Show: NSObject {
    
    var title: String = ""
    var desc: String = ""
    var fullDesc: String = ""
    
    var dayofWeek: DayOfWeek?
    
    var duration: Int!
    
    var start: Date!
    
    lazy var end : Date = {
        let endDate = self.start + self.duration.minutes
        return endDate
    }()
    
    var startTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: start)
    }
    
    var endTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        return dateFormatter.string(from: end)
    }
    
    static func create(title: String, desc: String, fullDesc: String, startTime: String, endTime: Int, dayofWeek: DayOfWeek) -> Show {
        let show = Show()
        
        let hour = Int(startTime.prefix(2))!; let min = Int(startTime.suffix(2))!
        
        let programStartDate = Date().startOfDay.startOfWeek!.add(component: Calendar.Component.day, value: dayofWeek.distance)
        
        let utcHours = Int(Calendar.current.timeZone.abbreviation()?.suffix(1) ?? "2") ?? 2
        let start = programStartDate.dateBySet(hour: hour - utcHours, min: min, secs: 0)
        
        show.start = start
        show.duration = endTime
        
        show.title = title
        show.desc = desc
        show.fullDesc = fullDesc
        
        show.dayofWeek = dayofWeek
        return show
    }
    
    func isPlaying() -> Bool {
        let date = Date()
        guard let start = start else { return false }
        return date.isBetweeen(date: start, andDate: end)
        
    }
}

struct Program {
    
    //NDA
    static var _shows: [Show] = []
    
    
    static func show() -> [Show] {
        return self._shows
    }
    
    static func getShows(by dayofWeek: DayOfWeek) -> [Show] {
        return show().filter({$0.dayofWeek == dayofWeek})
    }
    
    static func isPlaying(show: Show) -> Bool {
        return show.isPlaying()
    }
    
    static func getShowWhilePlaying() -> Show? {
        let show = _shows.first(where: {$0.isPlaying()})
        
        return show
    }
}
