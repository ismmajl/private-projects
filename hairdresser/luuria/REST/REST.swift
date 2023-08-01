//
//  REST.swift
//  luuria

import UIKit
import SwiftyJSON
import Alamofire

typealias ErrorMessage = String

struct ServiceREST {
    @discardableResult static func request(with rest: RequestREST, completion: @escaping ((ResponseREST) -> Void)) -> DataRequest {
        
        //  console("REQUEST: \(rest.description) parameters: \(rest.parameters ?? [:])")
        
        return Alamofire.request(rest.getURL(), method: rest.method, parameters: rest.parameters, encoding: rest.encoding, headers: rest.headers) .responseJSON(completionHandler: {(responseObject) in
            if responseObject.isUnAuthorized {
                AccountManager.delete()
                AccountManager.updateRootWindow()
                return
            }
            
            let responseREST: ResponseREST = ResponseREST(requestREST: rest, responseData: responseObject.result.value, responseHttp: responseObject.response, error: responseObject.error)
            switch responseObject.response?.statusCode {
            case 200:
                console("RESPONSE: 200 - 💚 METHOD: \(responseObject.request?.httpMethod ?? "UNK") \(responseObject.request?.debugDescription ?? "") time: \(responseObject.timeline.totalDuration)")
                break
            case 500:
                console("RESPONSE: 500 - ❤️ METHOD: \(responseObject.request?.httpMethod ?? "UNK") \(responseObject.request?.debugDescription ?? "") time: \(responseObject.timeline.totalDuration)")
                break
            case 404:
                console("RESPONSE: 404 - 💙 METHOD: \(responseObject.request?.httpMethod ?? "UNK") \(responseObject.request?.debugDescription ?? "") time: \(responseObject.timeline.totalDuration)")
                break
            case 400:
                console("RESPONSE: 400 - 🖤 METHOD: \(responseObject.request?.httpMethod ?? "UNK") \(responseObject.request?.debugDescription ?? "") time: \(responseObject.timeline.totalDuration)")
                break
            default:
                console("RESPONSE: 💛 \(responseObject.response?.statusCode.description ?? "UNK") METHOD: \(responseObject.request?.httpMethod ?? "UNK") \(responseObject.request?.debugDescription ?? "") time: \(responseObject.timeline.totalDuration)")
                break
            }
            completion(responseREST)
        })
    }
}
//MARK - Request Rest
struct RequestREST {
    var baseUrl: String { return Constants.serviceUrl }
    fileprivate var requestPath: String
    
    fileprivate var method: HTTPMethod
    var parameters : Parameters?
    var headers : HTTPHeaders = HTTPHeaders()
    var encoding : ParameterEncoding = URLEncoding.default
    
    init(resource: String, method: HTTPMethod = .get, parameters: Parameters? = nil) {
        self.requestPath = resource.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        self.method = method
        
        headers["Accept"] = "application/json"
        headers["X-Client-Token"] = Constants.clientAuthorizationToken

        headers["Accept-Language"] = "\(LanguageManager.current.iso)"
        
        
        if let token = AccountManager.userToken, !token.isEmpty {
            headers["Authorization"] = "Bearer " + token
        }
        
        self.parameters = parameters
        
        if method == .post || method == .put || method == .patch {
            encoding = JSONEncoding.default
        }
    }
    
    func getURL() -> URL {
        return URL(string: baseUrl.appending(self.requestPath))!
    }
    
    var description: String {
        return "Requesting: " + method.rawValue + ": " + getURL().absoluteString
    }
}

//MARK - Response Rest
struct ResponseREST {
    var requestREST: RequestREST
    fileprivate var responseData: Any?
    fileprivate var responseHttp : HTTPURLResponse?
    fileprivate var error: Error?
    
    /// get status code from http request, if no status code 0
    var statusCode : Int {
        if let statusCode = responseHttp?.statusCode {
            return statusCode
        }
        return 0
    }
    
    /// get json data from http response, if no data JSON.null is return
    var json: JSON {
        if let data = responseData {
            return JSON(data)
        }
        return JSON.null
    }
    
    var jsonData: JSON {
        return json["data"]
    }
    
    var pagination: Pagination? {
        return Pagination.create(from: json["pagination"])
    }
    
    /// returns true if http response status code is between 200 and 299
    var isHttpSuccess: Bool {
        if let response = self.responseHttp?.statusCode {
            return response >= 200 && response <= 299
        }
        
        return false
    }
    
    /// returns true if http response status code is 400
    var isHttpBad: Bool {
        if let response = self.responseHttp?.statusCode {
            return response == 400
        }
        
        return false
    }
    
    /// returns true if http response status code is 401
    var isHttpUnAuthorized: Bool {
        if let response = self.responseHttp?.statusCode {
            return response == 401
        }
        
        return false
    }
    
    /// returns true if http response status code is 500
    var isHttpServerError: Bool {
        if let response = self.responseHttp?.statusCode {
            return response >= 500 && response <= 599
        }
        
        return false
    }
    
    /// returns true if http response status code is 404
    var isHttpNotFound: Bool {
        if let response = self.responseHttp?.statusCode {
            return response == 404
        }
        
        return false
    }
    /// returns true if request fails
    var isError: Bool {
        return self.error != nil
    }
    
    /// returns true if request is successful
    var isSuccess: Bool {
        return !isError
    }
    
    /// returns message from error or tries to find on response for message
    var errorMessage : ErrorMessage? {
        
        if let errors = json["errors"].array, errors.count > 0 {
            let errorMessage: String = errors.map({ (item) -> String in
                if let message = item.string {
                    return message
                } else {
                    return ""
                }
            }).joined(separator: "\n")
            
            return errorMessage
        }
        
        
        if let error = json["error"].string {
            return error
        }
        
        if let error = json["message"].string {
            return error
        }
        
        if let error = error?.localizedDescription {
            return error
        }
        
        if let message =  json["detail"].string {
            return message
        }
        
        return nil
    }
    
    func hsError(message: String = "") -> HSError{
        let m = errorMessage ?? message
        
        return HSError(message: m, code: responseHttp?.statusCode ?? 0)
    }
    
}

//MARK - Extension DataResponse
extension DataResponse {
    var json : JSON {
        if let data = self.result.value {
            return JSON(data)
        }
        
        return JSON.null
    }
    
    var isSuccess: Bool {
        if let response = self.response?.statusCode {
            return response >= 200 && response <= 299
        }
        
        return false
    }
    
    var isBad: Bool {
        if let response = self.response?.statusCode {
            return response == 400
        }
        
        return false
    }
    
    var isError: Bool {
        return self.error != nil
    }
    
    var isUnAuthorized: Bool {
        if let response = self.response?.statusCode {
            return response == 401
        }
        
        return false
    }
    
    var errorMessage : String? {
        if let error = self.error?.localizedDescription {
            return error
        }
        
        if let message = json["detail"].string {
            return message
        }
        
        return nil
    }
}

struct HSError {
    var message: ErrorMessage
    var code : Int
    
    var accountNotExists : Bool {
        return code == 4102
    }
    
    var notExists: Bool {
        return code == 404
    }
    
    var isNetworkError: Bool {
        return true
    }
    
    static func noInternet() -> HSError {
        return HSError(message: "No Internet connection", code: 300)
    }
}

