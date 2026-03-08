//
//  ValidationRuleExtension.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 18/09/1447 AH.
//

import Foundation
import SwiftData

extension ValidationRule {
    func evaluate(
        _ value: String,
        attribute: String,
        cache: AsyncValidatorCache,
    ) async -> String? {
        switch self.type {
        case .name:
            return nil
            
        case .required(let customMsg):
            let isEmpty = value.trimmingCharacters(in: .whitespaces).isEmpty
            return isEmpty ? format(customMsg, "The :attribute is required.", attribute) : nil
            
        case .min(let length, let customMsg):
            let isInvalid = value.count < length
            return isInvalid ? format(customMsg, "The :attribute must be at least \(length) characters.", attribute) : nil
            
        case .max(let length, let customMsg):
            let isInvalid = value.count > length
            return isInvalid ? format(customMsg, "The :attribute must not be greater than \(length) characters.", attribute) : nil
            
        case .numeric(let customMsg):
            let isInvalid = !value.allSatisfy(\.isNumber)
            return isInvalid ? format(customMsg, "The :attribute must be a number.", attribute) : nil
            
        case .alpha(let customMsg):
            let isInvalid = value.isEmpty || !value.allSatisfy { $0.isLetter }
            return isInvalid ? format(customMsg, "The :attribute must only contain letters.", attribute) : nil
            
        case .alphaNum(let customMsg):
            let isInvalid = value.isEmpty || !value.allSatisfy { $0.isLetter || $0.isNumber }
            return isInvalid ? format(customMsg, "The :attribute must only contain letters and numbers.", attribute) : nil
            
        case .alphaDash(let customMsg):
            let isInvalid = value.isEmpty || value.unicodeScalars.contains { !CharacterSet.alphaDash.contains($0) }
            return isInvalid ? format(customMsg, "The :attribute must only contain letters, numbers, dashes and underscores.", attribute) : nil
            
        case .match(let targetValue, let customMsg):
            return value != targetValue ? format(customMsg, "The :attribute confirmation does not match.", attribute) : nil
            
        case .email(let customMsg):
            let isInvalid = try? Regex("[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").firstMatch(in: value) == nil
            return (isInvalid ?? true) ? format(customMsg, "The :attribute must be a valid email address.", attribute) : nil
            
        case .regex(let pattern, let customMsg):
            if value.isEmpty { return nil }
            let isInvalid = try? Regex(pattern).wholeMatch(in: value) == nil
            return (isInvalid ?? true) ? format(customMsg, "The :attribute format is invalid.", attribute) : nil
            
        case .url(let customMsg):
            if value.isEmpty { return nil }
            let isInvalid = URL(string: value) == nil || !value.contains(".")
            return isInvalid ? format(customMsg, "The :attribute must be a valid URL.", attribute) : nil
            
        case .digits(let length, let customMsg):
            if value.isEmpty { return nil }
            let isInvalid = !value.allSatisfy(\.isNumber) || value.count != length
            return isInvalid ? format(customMsg, "The :attribute must be exactly :value digits.", attribute) : nil
            
        case .inList(let values, let customMsg):
            let isInvalid = !value.isEmpty && !values.contains(value)
            return isInvalid ? format(customMsg, "The selected :attribute is invalid.", attribute) : nil
            
        case .uniqueAPI(let table, let column, let customMsg):
            let isUnique = await performAPICheck(value: value, table: table, column: column, cache: cache)
            return !isUnique ? format(customMsg, "The :attribute has already been taken.", attribute) : nil
            
        case .uniqueSwiftData(let checkClosure, let customMsg):
            guard let engine = await ValidateConfig.activeEngine,
                  case .swiftData(let container) = engine else {
                return "⚠️ Prepare ValidateConfig with .swiftData engine first"
            }
            
            let trimmedValue = value.trimmingCharacters(in: .whitespaces)
            
            let isUniqueResult = await cache.execute(key: "unique_sd_\(trimmedValue)") {
#if DEBUG
                print("🗄️ Checking local SwiftData uniqueness for: \(trimmedValue)")
#endif
                
                return await checkClosure(trimmedValue, container)
            }
            
            return !isUniqueResult ? format(customMsg, "The :attribute has already been taken.", attribute) : nil
        }
    }
    
    private func format(_ manualMessage: String?, _ defaultMessage: String, _ attribute: String) -> String {
        return (manualMessage ?? defaultMessage).replacingOccurrences(of: ":attribute", with: attribute)
    }
    
    private func performAPICheck(value: String, table: String, column: String, cache: AsyncValidatorCache) async -> Bool {
        guard let engine = await ValidateConfig.activeEngine,
              case .api(let finalURL) = engine,
              let url = URL(string: finalURL) else { return false }
        
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return await cache.execute(key: "unique_\(table)_\(column)_\(trimmed)") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let payload = ["table": table, "column": column, "value": trimmed]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else { return false }
                struct Res: Decodable { let isUnique: Bool }
                return (try? JSONDecoder().decode(Res.self, from: data))?.isUnique ?? false
            } catch { return false }
        }
    }
}
