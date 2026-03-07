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
public struct Validate: DynamicProperty {
    @State var value: String
    @State public private(set) var error: String?
    
    @State private var debouncer = Debouncer(delay: 0.5)
    @State private var asyncCache = AsyncValidatorCache()
    
    private let attributeName: String
    private let rules: [ValidationRule]
    
    public var wrappedValue: String {
        get { value }
        nonmutating set {
            value = newValue
            debouncer {
                await validate(newValue)
            }
        }
    }
    
    public struct ValidationProxy {
        public let binding: Binding<String>
        public let error: String?
    }
    
    public var projectedValue: ValidationProxy {
        ValidationProxy(
            binding: Binding(
                get: { self.wrappedValue },
                set: { self.wrappedValue = $0 }
            ),
            error: self.error
        )
    }
    
    public init(wrappedValue: String, _ rules: ValidationRule...) {
        self._value = State(initialValue: wrappedValue)
        self.rules = rules
        
        self.attributeName = rules.lazy.compactMap(\.extractedName).first ?? "field"
    }
    
    static func validateAll(_ fields: any ValidatableField...) async -> Bool {
        let mirror = Mirror(reflecting: self)
        var isFormValid: Bool = true
        
        for child in mirror.children {
            if let field = child.value as? any ValidatableField {
                let isFieldValid = await field.checkIsValid()
                if !isFieldValid {
                    isFormValid = false
                }
            }
        }
        
        return isFormValid
    }
    
    static func validateOnly(_ fields: any ValidatableField...) async -> Bool {
        var isFormValid: Bool = true
        
        for field in fields {
            let isFiledValid = await field.checkIsValid()
            if !isFiledValid {
                isFormValid = false
            }
        }
        
        return isFormValid
    }
    
    public func validate(_ value: String) async {
        error = nil
        for rule in rules {
            if let validationError = await rule.evaluate(value, attribute: attributeName, cache: asyncCache) {
                self.error = validationError
                
                return
            }
        }
    }
}

extension Validate: ValidatableField {
    public func checkIsValid() async -> Bool {
        // Check the value.
        await self.validate(wrappedValue)
        
        // Return true if there are not erorr
        return self.error == nil
    }
}
