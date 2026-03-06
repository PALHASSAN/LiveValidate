//
//  Debouncer.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 16/09/1447 AH.
//

import Foundation

@MainActor
public final class Debouncer {
    private var task: Task<Void, Never>?
    private let delay: TimeInterval
    
    public init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }
    
    public func callAsFunction(action: @escaping @MainActor @Sendable () async -> Void) {
        task?.cancel()
        
        task = Task {
            do {
                try await Task.sleep(for: .seconds(delay))
                
                await action()
            } catch {
                //
            }
        }
    }
    deinit {
        task?.cancel()
    }
}
