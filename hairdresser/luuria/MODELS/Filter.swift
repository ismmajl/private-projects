//
//  Filter.swift
//  luuria

import UIKit
import RealmSwift
import SwiftyJSON

enum SortType: String {
    case distance   = "distance"
    case rating     = "rating"
    case priceLow   = "price_low"
    case priceHigh  = "price_high"
    case none       = ""
    
    func toString() -> String {
        switch self {
        case .distance:
            return "Distance".localized
        case .rating:
            return "Rating".localized
        case .priceLow:
            return "Price low".localized
        case .priceHigh:
            return "Price high".localized
        case .none:
            return "None".localized
        }
    }
}

enum TimeType : String {
    case morning    = "morning"
    case noon       = "noon"
    case evening    = "evening"
    case none       = ""
    
    func toString() -> String {
        switch self {
        case .morning:
            return "Morning".localized + " (07:00 - 11:30)".localized
        case .noon:
            return "Noon".localized + " (12:00 - 17:30)".localized
        case .evening:
            return "Evening".localized + " (18:00 - 23:00)".localized
        case .none:
            return "All time".localized + " (07:00 - 23:00)".localized
        }
    }
}

class Filter: Object {
    @objc dynamic var id: Int = 0
    var categories: [Category] = []
    
    //selections
    var selectedCategories: [Category] = []
    var areFavorites: Bool? = nil
    var areRecommended: Bool? = nil
    var arePromoted: Bool? = nil
    var isDiscount: Bool? = nil
    var isLastMinute: Bool? = nil
    var selectedSalonId: Int?
    var selectedQuery: String?
    var selectedPlaceId: Int?
    var selectedDate : Date? = nil
    var selectedPriceFrom: Int = 0
    var selectedPriceTo: Int = Constants.maxPrice
    var selectedSortType: SortType = .none
    var selectedTimeType: TimeType = .none

 
    override class func primaryKey() -> String? {
        return "id"
    }
    override static func ignoredProperties() -> [String] {
        return ["categories"]
    }
    
    func getPreviousStates() {
        if let filter = ResourcesManager.filter {
            selectedCategories  = filter.selectedCategories
            areFavorites        = filter.areFavorites
            areRecommended      = filter.areRecommended
            arePromoted         = filter.arePromoted
            isDiscount          = filter.isDiscount
            isLastMinute        = filter.isLastMinute
            selectedPlaceId     = filter.selectedPlaceId
            selectedDate        = filter.selectedDate
            selectedPriceFrom   = filter.selectedPriceFrom
            selectedPriceTo     = filter.selectedPriceTo
            selectedSortType    = filter.selectedSortType
            selectedTimeType    = filter.selectedTimeType
        }
    }

    func getSources() {
        if let filter = ResourcesManager.filter{
            categories = filter.categories
        }
    }

    func isSet() -> Bool{
        if let first = selectedCategories.first, first.id != 0{
            return true
        }
        if let _ = areFavorites{
            return true
        }
        if let _ = isDiscount{
            return true
        }
        if let _ = isLastMinute {
            return true
        }
        if let _ = selectedPlaceId{
            return true
        }
        if let _ = selectedDate{
            return true
        }
        if selectedPriceFrom != 0 || selectedPriceTo != Constants.maxPrice{
            return true
        }
        if selectedSortType != .none{
            return true
        }
        if selectedTimeType != .none{
            return true
        }
        return false
    }
    
    func clearAll() {
        selectedCategories  = []
        areFavorites        = nil
        arePromoted         = nil
        areRecommended      = nil
        isDiscount          = nil
        isLastMinute        = nil
        selectedPlaceId     = nil
        selectedDate        = nil
        selectedPriceFrom   = 0
        selectedPriceTo     = Constants.maxPrice
        selectedSortType    = .none
        selectedTimeType    = .none
    }
}


extension Filter {
    static func == (lhs: Filter, rhs: Filter) -> Bool {
        guard lhs.selectedCategories.count == rhs.selectedCategories.count else { return false }
        
        let categoriesIntersectioned = Category.commonElements(lhs.selectedCategories, rhs.selectedCategories)
        if categoriesIntersectioned.count != lhs.selectedCategories.count || categoriesIntersectioned.count != rhs.selectedCategories.count{
            console("categories doesnt match")
            return false
        }
        
        if lhs.areFavorites != rhs.areFavorites {
            return false
        }
        if lhs.arePromoted != rhs.arePromoted {
            return false
        }
        if lhs.areRecommended != rhs.areRecommended {
            return false
        }
        if lhs.isDiscount != rhs.isDiscount {
            return false
        }
        if lhs.isLastMinute != rhs.isLastMinute {
            return false
        }
        if lhs.selectedPlaceId != rhs.selectedPlaceId {
            return false
        }
        if lhs.selectedDate != rhs.selectedDate {
            return false
        }
        if lhs.selectedPriceFrom != rhs.selectedPriceFrom {
            return false
        }
        if lhs.selectedPriceTo != rhs.selectedPriceTo {
            return false
        }
        if lhs.selectedSortType != rhs.selectedSortType {
            return false
        }
        if lhs.selectedTimeType != rhs.selectedTimeType {
            return false
        }
        return true
    }
    static func != (lhs: Filter, rhs: Filter) -> Bool{
        return !(lhs == rhs)
    }
}
