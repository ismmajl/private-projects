//
//  BookingREST.swift
//  luuria

import UIKit
import SwiftyJSON
import Alamofire


class BookingREST: NSObject {
    static func getBookings(page: Int = 1, isActual: Bool? = nil, q: String? = nil, completion: @escaping (([Booking]?, Pagination?, HSError?) -> Void)) {
        var parameters : Parameters = ["page" : page, "per_page": 20]

        if let isActual = isActual {
            parameters["momentum"] = isActual ? "actual" : "past"
        }
        if let q = q {
            parameters["q"] = q
        }
        let request = RequestREST(resource: "profile/my/reservations", method: .get, parameters: parameters)
        
        ServiceREST.request(with: request) { (response) in
            if let itemsJSON = response.jsonData.array, let pagination = response.pagination {
                var items: [Booking] = []
                for json in itemsJSON {
                    if let e = Booking.create(from: json) {
                        items.append(e)
                    }
                }
                completion(items, pagination, nil)
            }else {
                let error = response.hsError(message: Constants.errorLabel)
                completion(nil, nil, error)
            }
        }
    }
    static func getBooking(by id: Int, completion: @escaping ((Booking?, HSError?) -> Void)) {
        let request = RequestREST(resource: "profile/my/reservations/\(id)", method: .get, parameters: nil)
        
        ServiceREST.request(with: request) { (response) in
            
            if let item = Booking.create(from: response.jsonData) {
                completion(item, nil)
            } else {
                let error = response.hsError(message: Constants.errorLabel)
                completion(nil, error)
            }
        }
    }
    
    static func create(booking: Booking, completion: @escaping ((Booking?, HSError?) -> Void)) {
        
        let request = RequestREST(resource: "profile/my/reservations", method: .post, parameters: booking.toDictionary())
        
        ServiceREST.request(with: request) { (response) in
            if let booking = Booking.create(from: response.jsonData) {
                completion(booking, nil)
            }else {
                let error = response.hsError(message: Constants.errorLabel)
                completion(nil, error)
            }
        }

    }
    static func delete(booking: Booking, completion: @escaping ((Booking?, HSError?) -> Void)) {
        let request = RequestREST(resource: "profile/my/reservations/\(booking.id)", method: .delete, parameters: nil)
        
        ServiceREST.request(with: request) { (response) in
            if let booking = Booking.create(from: response.jsonData) {
                completion(booking, nil)
            }else {
                let error = response.hsError(message: Constants.errorLabel)
                completion(nil, error)
            }
        }
        
    }
}
