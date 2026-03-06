//
//  AsyncValidatorCache.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 17/09/1447 AH.
//

import Foundation

public actor AsyncValidatorCache {
    private var tasks: [String: Task<Bool, Never>] = [:]
    
    public init() {}
    
    public func execute(key: String, operation: @escaping @Sendable () async -> Bool) async -> Bool {
        if let existingTask = tasks[key] {
            return await existingTask.value
        }
        
        let task = Task {
            return await operation()
        }
        
        tasks[key] = task
        return await task.value
    }
}
