//
//  AsyncValidatorCache.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 17/09/1447 AH.
//

import Foundation

actor AsyncValidatorCache {
    private var results: [String: Bool] = [:]
    private var inProgress: [String: Task<Bool, Never>] = [:]
    
    init() {}
    
    func execute(key: String, operation: @escaping @Sendable () async -> Bool) async -> Bool {
        if let cached = results[key] { return cached }
        if let task = inProgress[key] { return await task.value }
        
        let task = Task { await operation() }
        inProgress[key] = task
        let result = await task.value
        
        results[key] = result
        inProgress.removeValue(forKey: key)
                
        return result
    }
}
