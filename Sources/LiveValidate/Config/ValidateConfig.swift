//
//  ValidateConfig.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 18/09/1447 AH.
//

import SwiftData
import Foundation

@MainActor
public struct ValidateConfig {
    public enum Engine: Sendable {
        case api(url: String)
        case swiftData(container: ModelContainer)
    }
    
    public static var activeEngine: Engine?
    
    public static func setup(engine: Engine) {
        self.activeEngine = engine
    }
}
