//
//  StorageManager.swift
//  upbike

import UIKit


class StorageManager {
    //MARK: - Save & Retrieve Images
    static func saveImageDocumentDirectory(image: UIImage, imageName: String) -> String {
        let fileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("RideImages")
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
        guard let url = NSURL(string: path), let imagePath = url.appendingPathComponent(imageName) else { return "" }
        let urlString = imagePath.absoluteString
        let imageData = image.jpegData(compressionQuality: 0.5)
        //let imageData = UIImagePNGRepresentation(image)
        fileManager.createFile(atPath: urlString as String, contents: imageData, attributes: nil)
        
        return urlString
    }
    
    static func getImageFromDocumentDirectory(paths: [String]) -> [UIImage] {
        let fileManager = FileManager.default
        var images: [UIImage] = []
        for path in paths {
            if fileManager.fileExists(atPath: path) {
                if let image = UIImage(contentsOfFile: path) {
                    images.append(image)
                }
            } else {
                print("Error GetImages: No Image was found")
            }
        }
        return images
    }
    
    static func getDirectoryPath() -> NSURL {
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("RideImages")
        guard let url = NSURL(string: path) else { return NSURL() }
        return url
    }
    
    static func deleteDirectory(path: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            do { try fileManager.removeItem(atPath: path) }
            catch { print("Delete ERROR: Couldn't remove file") }
        } else {
            print("Delete ERROR: No Image was found")
        }
    }
    
    static func deleteAllDirectories(paths: [String]) {
        let fileManager = FileManager.default
        paths.forEach { path in
            if fileManager.fileExists(atPath: path) {
                do { try fileManager.removeItem(atPath: path) }
                catch { print("Delete ERROR: Couldn't remove file") }
            } else {
                print("Delete ERROR: No Image was found")
            }
        }
    }
}
