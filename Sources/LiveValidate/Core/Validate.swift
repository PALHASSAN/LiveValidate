//
//  Validate.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 16/09/1447 AH.
//

import SwiftUI

@MainActor
@propertyWrapper
public struct Validate: DynamicProperty {
    @State public var value: String
    @State public var error: String?
    
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
    
    public func validate(_ value: String) async {
        error = nil
        
        for rule in rules {
            switch rule {
            case .name:
                continue
                
            case .required(let customMessage):
                if value.trimmingCharacters(in: .whitespaces).isEmpty {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute is required.")
                    return
                }
            case .min(let length, let customMessage):
                if value.count < length {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute must be at least \(length) characters.")
                    return
                }
            case .max(let length, let customMessage):
                if value.count > length {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute must not be greater than \(length) characters.")
                    return
                }
            case .numeric(let customMessage):
                if !value.allSatisfy(\.isNumber) {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute must be a number.")
                    return
                }
            case .alpha(let customMessage): // Only Letters are allowed.
                let allowed = value.allSatisfy { $0.isLetter }
                if !value.isEmpty && !allowed {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute must only contain letters.")
                    return
                }
            case .alphaNum(let customMessage): //  Only Letters and Numbers are allowed.
                let allowed = value.allSatisfy { $0.isLetter || $0.isNumber }
                if !value.isEmpty && !allowed {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute must only contain letters and numbers.")
                    return
                }
            case .alphaDash(let customMessage):
                let isInvalid = value.unicodeScalars.contains { !CharacterSet.alphaDash.contains($0) }
                if !value.isEmpty && isInvalid {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute must only contain letters, numbers, dashes and underscores.")
                    return
                }
            case .match(let newValue, let customMessage):
                if value != newValue {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute confirmation does not match.")
                    return
                }
            case .email(let customMessage):
                if !isValidEmail(value) {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute must be a valid email address.")
                    return
                }
            case .unique(let check, let customMessage):
                // Do not send request to server if the field empty
                let trimmedValue = value.trimmingCharacters(in: .whitespaces)
                
                let isUnique = await asyncCache.execute(key: "unique_\(trimmedValue)") {
                    await check(value)
                }
                
                if !isUnique {
                    error = formatMessage(customMessage, defaultMessage: "The :attribute has already been taken.")
                    return
                }
            case .regex(let pattern, let customMessage):
                if !value.isEmpty {
                    let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
                    if !predicate.evaluate(with: value) {
                        error = formatMessage(customMessage, defaultMessage: "The :attribute format is invalid.")
                        return
                    }
                }
            case .url(let customMessage):
                if !value.isEmpty {
                    if URL(string: value) == nil || !value.contains(".") {
                        error = formatMessage(customMessage, defaultMessage: "The :attribute must be a valid URL.")
                        return
                    }
                }
            case .digits(let length, let customMessage):
                if !value.isEmpty {
                    let isNumeric = value.allSatisfy(\.isNumber)
                    if !isNumeric || value.count != length {
                        error = formatMessage(customMessage, defaultMessage: "The :attribute must be exactly \(length) digits.")
                        return
                    }
                }
            case .inList(let values, let customMessage):
                if !value.isEmpty && !values.contains(value) {
                    error = formatMessage(customMessage, defaultMessage: "The selected :attribute is invalid.")
                    return
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        return emailPred.evaluate(with: email)
    }
    
    private func formatMessage(_ customMessage: String?, defaultMessage: String) -> String {
        let message = customMessage ?? defaultMessage
        return message.replacingOccurrences(of: ":attribute", with: attributeName)
    }
}
