//
//  AsyncValidatorCache.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 17/09/1447 AH.
//

import Foundation

actor AsyncValidatorCache {
    private var results: [String: Any] = [:]
    private var inProgress: [String: Any] = [:]
    
    init() {}
    
    func execute<T: Sendable>(key: String, operation: @escaping @Sendable () async -> T) async -> T {
        if let cached = results[key] as? T { return cached }
        if let task = inProgress[key] as? Task<T, Never> {
            return await task.value
        }
        
        let task = Task { await operation() }
        inProgress[key] = task
        
        let result = await task.value
        
        results[key] = result
        inProgress.removeValue(forKey: key)
        
        return result
        
        func clear() {
            results.removeAll()
            inProgress.removeAll()
        }
    }
}
