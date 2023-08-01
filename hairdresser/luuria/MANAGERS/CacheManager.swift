//
//  CacheManager.swift
//  luuria

import UIKit
import RealmSwift

class CacheManager: NSObject {
    static var shared: Realm {
        return instance()
    }
    
    static func store(object: Object) {
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(object, update: true)
        }
        
    }
    
    static func delete(object: Object) {
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(object)
        }
    }
    
    static func write(block: (()->())) {
        try! shared.write(block)
    }
    
    static func instance() -> Realm {
        
        do {
            let realm = try Realm()
            return realm
            
        } catch {
            print("Realm Database: Migration Need, database is reseting.")
            
            try! FileManager.default.removeItem(at: Realm.Configuration.defaultConfiguration.fileURL!)
            
            return instance()
        }
    }
}
