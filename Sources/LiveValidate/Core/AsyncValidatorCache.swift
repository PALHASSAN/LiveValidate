//
//  AsyncValidatorCache.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 17/09/1447 AH.
//

import Foundation

actor AsyncValidatorCache {
    private var tasks: [String: Task<Bool, Never>] = [:]
    
    init() {}
    
    func execute(key: String, operation: @escaping @Sendable () async -> Bool) async -> Bool {
        if let existingTask = tasks[key] {
            return await existingTask.value
        }
        
        let task = Task {
            return await operation()
        }
        
        tasks[key] = task
        tasks.removeValue(forKey: key)
        
        return await task.value
    }
}
