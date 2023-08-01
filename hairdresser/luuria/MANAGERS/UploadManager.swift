//
//  UploadManager.swift
//  luuria

import UIKit
import Alamofire


class UploadManager: NSObject {
}

extension UploadManager {
    static func uploadDirect(media: Media, completion: @escaping ((Media, Bool, HSError?) -> Void), progress: ((CGFloat) -> Void)? = nil) {
        
        var headers : HTTPHeaders = [
            "X-Client-Token" : Constants.clientAuthorizationToken,
            "Accept" : "application/json"
        ]
        if let token = AccountManager.userToken, AccountManager.isLogged {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        let request = RequestREST.init(resource: "uploads", method: .post, parameters: nil)
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(media.imageData, withName: "file", fileName: media.fileName, mimeType: "image/jpeg")
            if let pathComponents = media.getUrl()?.pathComponents, let folderName: String = pathComponents.item(at: pathComponents.count - 2) {
                multipartFormData.append(folderName.data(using: .ascii)!, withName: "folder_name")
            }
            
        }, usingThreshold: UInt64.init(), to: request.getURL(), method: .post, headers: headers) { (result) in
            switch result{
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    print("Succesfully uploaded")
                    if let m = Media.createData(from: response.json["data"]) {
                        completion(m, true, nil)
                        return
                    } else {
                        let error = HSError(message: "Something went wrong.", code: 4000)
                        completion(media, false, error)
                    }
                }
            case .failure(let error):
                print("Error in upload: \(error.localizedDescription)")
            }
        }
    }
}

