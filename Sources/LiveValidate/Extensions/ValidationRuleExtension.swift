//
//  ValidationRuleExtension.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 18/09/1447 AH.
//

import Foundation

extension ValidationRule {
    func evaluate(_ value: String, attribute: String, cache: AsyncValidatorCache) async -> String? {
        switch self {
        case .name:
            return nil
            
        case .required(let customMsg):
            let isEmpty = value.trimmingCharacters(in: .whitespaces).isEmpty
            return isEmpty ? format(customMsg, "The :attribute is required.", attribute) : nil
            
        case .min(let length, let customMsg):
            return value.count < length ? format(customMsg, "The :attribute must be at least \(length) characters.", attribute) : nil
            
        case .max(let length, let customMsg):
            return value.count > length ? format(customMsg, "The :attribute must not be greater than \(length) characters.", attribute) : nil
            
        case .numeric(let customMsg):
            return !value.allSatisfy(\.isNumber) ? format(customMsg, "The :attribute must be a number.", attribute) : nil
            
        case .alpha(let customMsg):
            let isInvalid = value.isEmpty || !value.allSatisfy { $0.isLetter }
            return isInvalid ? format(customMsg, "The :attribute must only contain letters.", attribute) : nil
            
        case .alphaNum(let customMsg):
            let isInvalid = value.isEmpty || !value.allSatisfy { $0.isLetter || $0.isNumber }
            return isInvalid ? format(customMsg, "The :attribute must only contain letters and numbers.", attribute) : nil
            
        case .alphaDash(let customMsg):
            let isInvalid = value.isEmpty || value.unicodeScalars.contains { !CharacterSet.alphaDash.contains($0) }
            return isInvalid ? format(customMsg, "The :attribute must only contain letters, numbers, dashes and underscores.", attribute) : nil
            
        case .match(let newValue, let customMsg):
            return value != newValue ? format(customMsg, "The :attribute confirmation does not match.", attribute) : nil
            
        case .email(let customMsg):
            return !isValidEmail(value) ? format(customMsg, "The :attribute must be a valid email address.", attribute) : nil
            
        case .unique(let check, let customMsg):
            let trimmedValue = value.trimmingCharacters(in: .whitespaces)
            let isUnique = await cache.execute(key: "unique_\(trimmedValue)") { await check(value) }
            return !isUnique ? format(customMsg, "The :attribute has already been taken.", attribute) : nil
            
        case .regex(let pattern, let customMsg):
            if value.isEmpty { return nil }
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            return !predicate.evaluate(with: value) ? format(customMsg, "The :attribute format is invalid.", attribute) : nil
            
        case .url(let customMsg):
            if value.isEmpty { return nil }
            let isInvalid = URL(string: value) == nil || !value.contains(".")
            return isInvalid ? format(customMsg, "The :attribute must be a valid URL.", attribute) : nil
            
        case .digits(let length, let customMsg):
            if value.isEmpty { return nil }
            let isInvalid = !value.allSatisfy(\.isNumber) || value.count != length
            return isInvalid ? format(customMsg, "The :attribute must be exactly \(length) digits.", attribute) : nil
            
        case .inList(let values, let customMsg):
            let isInvalid = !value.isEmpty && !values.contains(value)
            return isInvalid ? format(customMsg, "The selected :attribute is invalid.", attribute) : nil
        }
    }
    
    private func format(_ customMessage: String?, _ defaultMessage: String, _ attribute: String) -> String {
        return (customMessage ?? defaultMessage).replacingOccurrences(of: ":attribute", with: attribute)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
}
