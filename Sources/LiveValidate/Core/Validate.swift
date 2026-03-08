//
//  Validate.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 16/09/1447 AH.
//

import SwiftUI

@MainActor
public protocol ValidatableField {
    func checkIsValid() async -> Bool
}

@MainActor
@propertyWrapper
public struct Validate<Value>: DynamicProperty {
    @State var value: Value
    @State public private(set) var error: String?
    
    @State private var debouncer = Debouncer(delay: 0.5)
    @State private var asyncCache = AsyncValidatorCache()
    
    private let attributeName: String
    private let rules: [ValidationRule]
    
    public var wrappedValue: Value {
        get { value }
        nonmutating set {
            value = newValue
            debouncer {
                await validate(newValue)
            }
        }
    }
    
    public struct ValidationProxy: ValidatableField {
        public let binding: Binding<Value>
        public let error: String?
        let validateAction: @Sendable () async -> Bool
        
        public func checkIsValid() async -> Bool {
            await validateAction()
        }
    }
    
    public var projectedValue: ValidationProxy {
        ValidationProxy(
            binding: Binding(
                get: { self.wrappedValue },
                set: { self.wrappedValue = $0 }
            ),
            error: self.error,
            validateAction: { await self.checkIsValid() }
        )
    }
    
    public init(wrappedValue: Value, _ rules: ValidationRule...) {
        self._value = State(initialValue: wrappedValue)
        self.rules = rules
        
        self.attributeName = rules.lazy.compactMap(\.extractedName).first ?? "field"
    }
    
    func validate(_ value: Value) async {
        error = nil
        let stringValue = "\(value)"
        
        for rule in rules {
            if let validationError = await rule.evaluate(stringValue, attribute: attributeName, cache: asyncCache) {
                self.error = validationError
                
                return
            }
        }
    }
}

extension Validate: ValidatableField {
    public func checkIsValid() async -> Bool {
        // Check the value
        await self.validate(wrappedValue)
        
        // Return true if there are not error
        return self.error == nil
    }
}

// MARK: - Validate
public extension View {
    @MainActor
    func validateAll() async -> Bool {
        let mirror = Mirror(reflecting: self)
        var isFormValid: Bool = true
        
        for child in mirror.children {
            if let field = child.value as? any ValidatableField {
                if await !field.checkIsValid() {
                    isFormValid = false
                }
            }
        }
        return isFormValid
    }
    
    @MainActor
    func validateOnly(_ fields: any ValidatableField...) async -> Bool {
        var isFormValid: Bool = true
        
        for field in fields {
            if await !field.checkIsValid() {
                isFormValid = false
            }
        }
        
        return isFormValid
    }
}
