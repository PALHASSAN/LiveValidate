//
//  ValidationRule.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 16/09/1447 AH.
//

import SwiftData
import Foundation

public struct ValidationRule: Sendable {
    enum RuleType: @unchecked Sendable {
        case name(String)
        case required(String?)
        case min(Int, String?)
        case max(Int, String?)
        case alpha(String?)
        case alphaNum(String?)
        case alphaDash(String?)
        case email(String?)
        case numeric(String?)
        case match(String, String?)
        case regex(String, String?)
        case url(String?)
        case digits(Int, String?)
        case inList([String], String?)
        case uniqueAPI(table: String, column: String, message: String?)
        case uniqueSwiftData(check: @Sendable (String, ModelContainer) async -> Bool, message: String?)
    }
    
    let type: RuleType
    
    var extractedName: String? {
        if case .name(let name) = type { return name }
        return nil
    }
    
    init(type: RuleType) {
        self.type = type
    }
}

public extension ValidationRule {
    
    /// (Optional) Sets a custom display name for the field in error messages.
    /// If not provided, it defaults to "field".
    ///
    /// - Parameter attributeName: The custom name (e.g., "Email Address") to be used in validation messages.
        static func name(_ attributeName: String) -> Self { .init(type: .name(attributeName)) }
    
    /// Ensures the field is not empty and does not contain only whitespace.
    /// - Parameter message: A custom error message.
    static func required(_ message: String? = nil) -> Self { .init(type: .required(message)) }
    
    /// Validates that the input length is at least the specified number of characters.
    /// - Parameters:
    ///   - length: The minimum required length.
    ///   - message: A custom error message.
    static func min(_ length: Int, _ message: String? = nil) -> Self { .init(type: .min(length, message)) }
    
    /// Validates that the input length does not exceed the specified number of characters.
    /// - Parameters:
    ///   - length: The maximum allowed length.
    ///   - message: A custom error message.
    static func max(_ length: Int, _ message: String? = nil) -> Self { .init(type: .max(length, message)) }
    
    /// Validates that the input contains only alphabetic characters (letters).
    /// - Parameter message: A custom error message.
    static func alpha(_ message: String? = nil) -> Self { .init(type: .alpha(message)) }
    
    /// Validates that the input contains only alphanumeric characters (letters and numbers).
    /// - Parameter message: A custom error message.
    static func alphaNum(_ message: String? = nil) -> Self { .init(type: .alphaNum(message)) }
    
    /// Validates that the input contains letters, numbers, dashes (-), and underscores (_).
    /// - Parameter message: A custom error message.
    static func alphaDash(_ message: String? = nil) -> Self { .init(type: .alphaDash(message)) }
    
    /// Validates that the input follows a standard email format.
    /// - Parameter message: A custom error message.
    static func email(_ message: String? = nil) -> Self { .init(type: .email(message)) }
    
    /// Validates that the input contains only numeric digits.
    /// - Parameter message: A custom error message.
    static func numeric(_ message: String? = nil) -> Self { .init(type: .numeric(message)) }
    
    /// Ensures the input value exactly matches another provided string (e.g., password confirmation).
    /// - Parameters:
    ///   - value: The string value to compare against.
    ///   - message: A custom error message.
    static func match(_ value: String, _ message: String? = nil) -> Self { .init(type: .match(value, message)) }
    
    /// Validates the input against a custom Regular Expression pattern.
    /// - Parameters:
    ///   - pattern: The Regex string pattern.
    ///   - message: A custom error message.
    static func regex(_ pattern: String, _ message: String? = nil) -> Self { .init(type: .regex(pattern, message)) }
    
    /// Validates that the input is a correctly formatted URL.
    /// - Parameter message: A custom error message.
    static func url(_ message: String? = nil) -> Self { .init(type: .url(message)) }
    
    /// Validates that the input consists of exactly the specified number of digits.
    /// - Parameters:
    ///   - length: The required number of digits.
    ///   - message: A custom error message.
    static func digits(_ length: Int, _ message: String? = nil) -> Self { .init(type: .digits(length, message)) }
    
    /// Restricts the input to values present in a predefined list.
    /// - Parameters:
    ///   - values: An array of allowed string values.
    ///   - message: A custom error message.
    static func inList(_ values: [String], _ message: String? = nil) -> Self { .init(type: .inList(values, message)) }
    
    /// Checks for value uniqueness via a remote API request.
    /// - Parameters:
    ///   - table: The database table name.
    ///   - column: The database column name.
    ///   - message: A custom error message.
    static func unique(table: String, column: String, _ message: String? = nil) -> Self {
        .init(type: .uniqueAPI(table: table, column: column, message: message))
    }
    
    /// Checks for value uniqueness locally within a SwiftData container.
    /// - Parameters:
    ///   - model: The SwiftData model type to check.
    ///   - field: The specific string field (KeyPath) to verify.
    ///   - message: A custom error message.
    static func unique<T: PersistentModel>(model: T.Type, field: KeyPath<T, String>, _ message: String? = nil) -> Self {
        let safeField = SafeKeyPath(keyPath: field)
        return .init(type: .uniqueSwiftData(check: { value, container in
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<T>()
            do {
                let safeKeyPath = safeField.keyPath
                let allRecords = try context.fetch(descriptor)
                return !allRecords.contains { $0[keyPath: safeKeyPath].lowercased() == value.lowercased() }
            } catch {
                return false
            }
        }, message: message))
    }
}

private struct SafeKeyPath<Root, Value>: @unchecked Sendable {
    let keyPath: KeyPath<Root, Value>
}
