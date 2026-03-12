//
//  ValidateConfig.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 18/09/1447 AH.
//

import SwiftData
import Foundation

public protocol DatabasePresenceVerifier: Sendable {
    func count(table: String, column: String, value: String) async -> Int
}

@MainActor
public struct ValidateConfig {
    public enum Engine: @unchecked Sendable {
        case api(url: String)
        case swiftData(container: ModelContainer)
        
        // Any DB package like BoltSpark
        case custom(DatabasePresenceVerifier)
    }
    
    public static var activeEngine: Engine?
    
    public static func setup(engine: Engine) {
        self.activeEngine = engine
    }
}
