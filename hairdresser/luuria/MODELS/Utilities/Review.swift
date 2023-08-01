//
//  Review.swift
//  luuria

import UIKit
import RealmSwift
import SwiftyJSON
import Alamofire

class Review: Object {
    
    @objc dynamic var id: Int = 0
    @objc dynamic var title: String = ""
    @objc dynamic var comment: String = ""
    @objc dynamic var average: Double = 0.0
    @objc dynamic var user: User?
    @objc dynamic var employee: Employee?
    @objc dynamic var booking: Booking?
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()
    @objc dynamic var priceValue: Double = 0.0
    @objc dynamic var serviceValue: Double = 0.0
    @objc dynamic var beratungValue: Double = 0.0
    @objc dynamic var punctualityValue: Double = 0.0
    
    
    static func create(from json: JSON) -> Review? {
        guard let id = json["id"].int, let title = json["message"].string, let average = json["average"].string?.toDouble() else { return nil }
        
        let r = Review()
        r.id = id
        r.title = title
        r.comment = json["message"].string ?? ""
        r.average = average
        r.updatedAt = json["updated_at"].date ?? Date()
        r.createdAt = json["created_at"].date ?? Date()
        
        if let user = User.create(from: json["user"]) {
            r.user = user
        }
        if let employee = Employee.create(from: json["employee"]) {
            r.employee = employee
        }
        return r
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    func toDictionary() -> Parameters {
        let parameters : Parameters = [
            "price" : Int(priceValue),
            "service" : Int(serviceValue),
            "advice" : Int(beratungValue),
            "punctual" : Int(punctualityValue),
            "employee_id": employee!.id,
            "reservation_id": booking!.id,
            "message": comment
        ]
        return parameters
    }
}
