//
//  ValidationRuleExtension.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 18/09/1447 AH.
//

import Foundation
import SwiftData

extension ValidationRule {
    func evaluate(_ value: String, attribute: String, cache: AsyncValidatorCache) async -> String? {
        switch self.type {
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
            
        case .uniqueAPI(let table, let column, let customMsg):
            guard let engine = await ValidateConfig.activeEngine,
                  case .api(let finalURL) = engine else { return nil }
            
            let trimmedValue = value.trimmingCharacters(in: .whitespaces)
            let isUniqueResult = await cache.execute(key: "unique_\(table)_\(column)_\(trimmedValue)") {
                
                guard let url = URL(string: finalURL) else {
                    print("🛑 Error: Invalid URL -> \(finalURL)")
                    return false
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                
                let payload: [String: Any] = [
                    "table": table,
                    "column": column,
                    "value": trimmedValue,
                    column: trimmedValue
                ]
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
                
#if DEBUG
                print("📡 Sending Request to: \(url.absoluteString)")
#endif
                
                if let body = String(data: request.httpBody ?? Data(), encoding: .utf8) {
                    print("📦 Payload: \(body)")
                }
                
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("🌐 HTTP Status: \(httpResponse.statusCode)")
                        
                        if let rawJSON = String(data: data, encoding: .utf8) {
                            print("📩 Raw Server Response: \(rawJSON)")
                        }
                        
                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else {
#if DEBUG
                            print("⚠️ Server returned error status.")
#endif
                            return false
                        }
                        
                    }
                    
                    struct ServerResponse: Decodable {
                        let isUnique: Bool
                    }
                    
                    
                    if let decoded = try? JSONDecoder().decode(ServerResponse.self, from: data) {
                        return decoded.isUnique
                    }
                    
                    return false
                } catch {
#if DEBUG
                    print("❌ [Bolt] Network Error: \(error.localizedDescription)")
#endif
                    return false
                }
            }
            return !isUniqueResult ? format(customMsg, "The :attribute has already been taken.", attribute) : nil
            
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
            
            return !isUniqueResult ? format(customMsg, "The :attribute has already been taken locally.", attribute) : nil
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
