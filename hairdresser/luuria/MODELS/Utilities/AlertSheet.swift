//
//  AlertSheet.swift
//  luuria

import UIKit
import SwiftyJSON
import Alamofire

typealias AlertActionCompletion = (AlertAction) -> ()

class AlertAction: NSObject {
    
    var rightASImage: UIImage?
    var name: String = ""
    var isSelected: Bool = false
    
    var completion: AlertActionCompletion?
    
    init(name: String, rightASImage: UIImage? = nil, isSelected: Bool = false, completion: AlertActionCompletion? = nil) {
        self.isSelected = isSelected
        self.rightASImage = rightASImage
        self.name = name
        self.completion = completion
    }
}

