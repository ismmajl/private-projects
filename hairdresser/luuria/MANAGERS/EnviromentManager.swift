//
//  EnviromentManager.swift
//  luuria

import Foundation

enum Environment: String {
    case production = "production"
    case staging = "staging"
    case local = "local"
    
    static func list() -> [Environment] {
        return [.production, .staging, .local]
    }
    
    var string : String {
        return self.rawValue.capitalized
    }
}

class EnvironmentManager {
    static var shared = EnvironmentManager()
    fileprivate init () {
        if let current = UserDefaults.standard.string(forKey: "environment"), let env = Environment.init(rawValue: current)  {
            self.current = env
        }
    }
    
    fileprivate(set) var current: Environment = Constants.defaultEnvironment
    
    var list: [Environment] {
        return Environment.list()
    }
    
    func change(to env: Environment) {
        self.current = env
        UserDefaults.standard.set(env.rawValue, forKey: "environment")
    }
}
