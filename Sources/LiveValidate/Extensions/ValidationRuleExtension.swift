//
//  ValidationRuleExtension.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 18/09/1447 AH.
//

import Foundation
import SwiftData

nonisolated(unsafe) fileprivate let sharedISOFormatter = ISO8601DateFormatter()
fileprivate let sharedDateFormatter = DateFormatter()

extension ValidationRule {
    func evaluate(
        _ rawValue: any Sendable,
        attribute: String,
        cache: AsyncValidatorCache,
    ) async -> String? {
        let stringValue = (rawValue as? String) ?? "\(rawValue)"
        let trimmedValue = stringValue.trimmingCharacters(in: .whitespaces)
        let value = stringValue
        
        switch self.type {
        case .name:
            return nil
            
        case .required(let customMsg):
            let isEmpty = value.trimmingCharacters(in: .whitespaces).isEmpty
            return isEmpty ? format(customMsg, "The :attribute is required.", attribute) : nil
            
        case .requiredIf(let condition, let msg):
            if condition && trimmedValue.isEmpty {
                return format(msg, "The :attribute field is required.", attribute)
            }
            return nil
            
        case .min(let length, let customMsg):
            return value.count < length ? format(customMsg, "The :attribute must be at least :value characters.", attribute, "\(length)") : nil
            
        case .max(let length, let customMsg):
            return value.count > length ? format(customMsg, "The :attribute must not be greater than :value characters.", attribute, "\(length)") : nil
            
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
            let isInvalid = try? /[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}/.firstMatch(in: value) == nil
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
            return isInvalid ? format(customMsg, "The :attribute must be exactly :value digits.", attribute, "\(length)") : nil
            
        case .inList(let values, let customMsg):
            let isInvalid = !value.isEmpty && !values.contains(value)
            return isInvalid ? format(customMsg, "The selected :attribute is invalid.", attribute) : nil
            
        case .uniqueAPI(let table, let column, let customMsg):
            if let engine = await ValidateConfig.activeEngine {
                switch engine {
                case .custom(let verifier):
                    let count = await cache.execute(key: "unique_db_\(table)_\(column)_\(trimmedValue)") {
                        return await verifier.count(table: table, column: column, value: trimmedValue)
                    }
                    return count == 0 ? nil : format(customMsg, "The :attribute has already been taken.", attribute)
                    
                case .api:
                    let isUnique = await performAPICheck(value: value, table: table, column: column, cache: cache)
                    return !isUnique ? format(customMsg, "The :attribute has already been taken.", attribute) : nil
                    
                case .swiftData:
                    return "⚠️ Please use .uniqueSwiftData() for SwiftData."
                }
            }
            return nil
            
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
            
        case .between(let min, let max, let customMsg):
            let isInvalid = value.count < min || value.count > max
            return isInvalid ? format(customMsg, "The :attribute must be between :value characters.", attribute, "\(min)-\(max)") : nil
            
        case .integer(let customMsg):
            return Int(trimmedValue) == nil ? format(customMsg, "The :attribute must be an integer.", attribute) : nil
            
        case .decimal(let customMsg):
            return Double(trimmedValue) == nil ? format(customMsg, "The :attribute must be a decimal number.", attribute) : nil
            
        case .date(let customMsg):
            if rawValue is Date { return nil }
            return sharedISOFormatter.date(from: trimmedValue) == nil ? format(customMsg, "The :attribute is not a valid date.", attribute) : nil
            
        case .dateFormat(let formatStr, let customMsg):
            if rawValue is Date { return nil }
            sharedDateFormatter.dateFormat = formatStr
            return sharedDateFormatter.date(from: trimmedValue) == nil ? format(customMsg, "The :attribute does not match the format :value.", attribute, formatStr) : nil
            
        case .after(let date, let customMsg):
            guard let inputDate = (rawValue as? Date) ?? sharedISOFormatter.date(from: trimmedValue) else { return nil }
            let dateStr = sharedISOFormatter.string(from: date)
            return inputDate <= date ? format(customMsg, "The :attribute must be a date after :value.", attribute, dateStr) : nil
            
        case .afterOrEqual(let date, let customMsg):
            guard let inputDate = (rawValue as? Date) ?? sharedISOFormatter.date(from: trimmedValue) else { return nil }
            let dateStr = sharedISOFormatter.string(from: date)
            return inputDate < date ? format(customMsg, "The :attribute must be a date after or equal to :value.", attribute, dateStr) : nil
            
        case .before(let date, let customMsg):
            guard let inputDate = (rawValue as? Date) ?? sharedISOFormatter.date(from: trimmedValue) else { return nil }
            let dateStr = sharedISOFormatter.string(from: date)
            return inputDate >= date ? format(customMsg, "The :attribute must be a date before :value.", attribute, dateStr) : nil
            
        case .beforeOrEqual(let date, let customMsg):
            guard let inputDate = (rawValue as? Date) ?? sharedISOFormatter.date(from: trimmedValue) else { return nil }
            let dateStr = sharedISOFormatter.string(from: date)
            return inputDate > date ? format(customMsg, "The :attribute must be a date before or equal to :value.", attribute, dateStr) : nil
            
        case .boolean(let customMsg):
            if rawValue is Bool { return nil }
            let bools = ["true", "false", "1", "0", "yes", "no"]
            return !bools.contains(trimmedValue.lowercased()) ? format(customMsg, "The :attribute field must be true or false.", attribute) : nil
            
        case .iban(let customMsg):
            let cleanIban = trimmedValue.replacingOccurrences(of: " ", with: "")
            let isInvalid = try? /^[A-Z]{2}[0-9]{2}[A-Z0-9]{4,30}$/.firstMatch(in: cleanIban) == nil
            return (isInvalid ?? true) ? format(customMsg, "The :attribute is not a valid IBAN.", attribute) : nil
        }
    }
    
    private func format(_ manualMessage: String?, _ defaultMessage: String, _ attribute: String, _ value: String = "") -> String {
        return (manualMessage ?? defaultMessage)
            .replacingOccurrences(of: ":attribute", with: attribute)
            .replacingOccurrences(of: ":value", with: value)
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
