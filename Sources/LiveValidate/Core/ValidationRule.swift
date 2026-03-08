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
    static func name(_ attributeName: String) -> Self { .init(type: .name(attributeName)) }
    static func required(_ message: String? = nil) -> Self { .init(type: .required(message)) }
    static func min(_ length: Int, _ message: String? = nil) -> Self { .init(type: .min(length, message)) }
    static func max(_ length: Int, _ message: String? = nil) -> Self { .init(type: .max(length, message)) }
    static func alpha(_ message: String? = nil) -> Self { .init(type: .alpha(message)) }
    static func alphaNum(_ message: String? = nil) -> Self { .init(type: .alphaNum(message)) }
    static func alphaDash(_ message: String? = nil) -> Self { .init(type: .alphaDash(message)) }
    static func email(_ message: String? = nil) -> Self { .init(type: .email(message)) }
    static func numeric(_ message: String? = nil) -> Self { .init(type: .numeric(message)) }
    static func match(_ value: String, _ message: String? = nil) -> Self { .init(type: .match(value, message)) }
    static func regex(_ pattern: String, _ message: String? = nil) -> Self { .init(type: .regex(pattern, message)) }
    static func url(_ message: String? = nil) -> Self { .init(type: .url(message)) }
    static func digits(_ length: Int, _ message: String? = nil) -> Self { .init(type: .digits(length, message)) }
    static func inList(_ values: [String], _ message: String? = nil) -> Self { .init(type: .inList(values, message)) }
    
    static func unique(table: String, column: String, _ message: String? = nil) -> Self {
        .init(type: .uniqueAPI(table: table, column: column, message: message))
    }
    
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
