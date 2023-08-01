//
//  Booking.swift
//  luuria

import UIKit
import SwiftyJSON
import Alamofire
import RealmSwift

enum BookingStatus: String {
    case pending
    case active
    case confirmed
    case cancelled
}

class Booking: Object {
    
    static var activeBooking = Booking()
    
    @objc dynamic var id: Int = 0
    @objc dynamic var employee: Employee?
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var slot: Slot? = nil
    @objc dynamic var creditCardId: Int = 0
    var distancePrice: Double = 0.0
    
    var otherAmount: Double = 0.0
    var totalAmount: Double = 0.0
    var discount: Double = 0.0
    var currency: String = "CHF"
    @objc dynamic var providerNote: String = ""
    @objc dynamic var note: String = ""
    
    var services : [EmployeeService] = []
    @objc dynamic var startTime: Date = Date()
    @objc dynamic var endTime: Date = Date()
    var isFinished: Bool = false
    var isReviewed: Bool = false
    
    //ADDRESS
    @objc dynamic var address : Address? = nil
    
    @objc dynamic var site: String = ""
    var siteLocation: SiteLocation {
        return SiteLocation(rawValue: site) ?? .provider
    }
    
    @objc dynamic var status: String = ""
    var bookingStatus: BookingStatus {
        return BookingStatus(rawValue: status) ?? .active
    }
    
    //PAYMENT
    @objc dynamic var paypalToken: String = ""
    @objc dynamic var paypalMetaDataID: String = ""
    
    @objc dynamic var type: String = ""
    var paymentType: PaymentType {
        return PaymentType(rawValue: type) ?? .site
    }
    
    static func create(from json : JSON) -> Booking? {
        guard let id = json["id"].int else { return nil }
        
        let item = Booking()
        item.id = id
        item.createdAt = json["created_at"].date ?? Date()
        item.startTime = json["start_time"].date ?? Date()
        item.endTime = json["end_time"].date ?? Date()
        
        item.note = json["note"].string ?? ""
        item.providerNote = json["provider_note"].string ?? ""
        
        if let address = Address.create(from: json["address"]) {
            item.address = address
        }
        if let employee = Employee.create(from: json["employee"]) {
            item.employee = employee
        }
        
        //SERVICES
        if let jsonItems = json["items"].array {
            for jsonItem in jsonItems {
                if let subItem = EmployeeService.create(from: jsonItem) {
                    subItem.address = item.address
                    subItem.employee = item.employee
                    item.services.append(subItem)
                }
            }
        }
        item.isFinished = json["is_finished"].bool ?? false
        item.isReviewed = json["is_reviewed"].bool ?? false
        
        
        item.otherAmount = json["other_amount"].double ?? 0.0
        item.totalAmount = json["total_amount"].double ?? 0.0
        item.discount = json["discount"].double ?? 0.0
        item.currency = json["currency"].string ?? "CHF"
        
        item.status = json["status"].string ?? "active"
        item.site = json["site_location"].string ?? "provider"
        item.type = json["payment_type"].string ?? "site_cash"
        return item
    }
    
    func servicesID() -> [Int] {
        var ids: [Int] = []
        for item in services {
            ids.append(item.id)
        }
        return ids
    }
    
    func getDuration() -> Int{
        return services.map({$0.getDuration() + $0.subItems.map({$0.getDuration()}).reduce(0, +) }).reduce(0, +)
    }
    func getFullPrice() -> Double {
        //        return services.map({$0.price}).reduce(0, +)
        return services.map({$0.price + $0.subItems.map({$0.price}).reduce(0, +) }).reduce(0, +)
    }
    func getDiscountedPrice() -> Double {
        return services.map({$0.salePrice + $0.subItems.map({$0.salePrice}).reduce(0, +) }).reduce(0, +)
    }
    func getCategories() -> [Category] {
        let categories = services.compactMap({$0.category})
        var uniqCategories: [Category] = []
        for item in categories {
            if !uniqCategories.contains(where: {$0.id == item.id}) {
                uniqCategories.append(item)
            }
        }
        return uniqCategories
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    func isActual() -> Bool {
        if endTime < Date() {
            return false
        }
        return true
    }
    func toDictionary() -> Parameters {
        var parameters : Parameters = [
            "id"                : id,
            "services"          : servicesToDictionary(),
            "site_location"     : siteLocation.rawValue,
            "payment_type"      : paymentType.rawValue,
            "provider_note"     : providerNote,
            "note"              : note,
            "sale_amount"       : getDiscountedPrice(),
            "total_amount"      : getFullPrice(),
            "other_amount"      : distancePrice,
            "services_count"    : getServicesCount()
        ]
        if let slot = slot {
            parameters["start_time"] = slot.date.toBookingDate
        }
        if let employee = employee {
            parameters["employee_id"] = employee.id
        }
        
        if siteLocation == .user {
            if let employee = employee {
                if let details = employee.details {
                    if details.startAddressId != 0 {
                        parameters["site_id"] = details.startAddressId
                    }else {
                        if let addressId = self.address?.id {
                            parameters["site_id"] = addressId
                        }
                    }
                }else {
                    if let addressId = self.address?.id {
                        parameters["site_id"] = addressId
                    }
                }
            }else {
                if let addressId = self.address?.id {
                    parameters["site_id"] = addressId
                }
            }
        }else {
            if let addressId = self.address?.id {
                parameters["site_id"] = addressId
            }
        }
        
        if self.paymentType == .paypal {
            parameters["paypal_token"] = self.paypalToken
            parameters["paypal_metadata_id"] = self.paypalMetaDataID
        }
        if self.paymentType == .creditCard {
            parameters["credit_card_id"] = self.creditCardId
        }
        console("parameters: \(parameters)")
        return parameters
    }
    
    fileprivate func servicesToDictionary() -> [Parameters]{
        var servicesDict: [Parameters] = []
        
        for service in services {
            var item: Parameters = [:]
            item["id"] = service.id
            
            if service.serviceType == .extra{
                let ids: [Int] = service.subItems.map({ $0.id })
                item["extra"] = ids
            }else if service.serviceType == .option {
                item["option"] = service.subItems.first?.id ?? 0
            }
            servicesDict.append(item)
        }
        return servicesDict
    }
    
    fileprivate func getServicesCount() -> Int{
        return services.map({$0.getCount()}).reduce(0, +)
    }
}
