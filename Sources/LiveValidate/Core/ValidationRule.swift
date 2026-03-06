//
//  ValidationRule.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 16/09/1447 AH.
//

public enum ValidationRule: @unchecked Sendable {
    case name(_ attrubiteName: String) // Optional. If the developer want to change attrubite name. By default "field"
    var extractedName: String? {
        if case .name(let name) = self { return name }
        return nil
    }
    
    case required(_ message: String? = nil)
    case min(_ length: Int, _ message: String? = nil)
    case max(_ length: Int, _ message: String? = nil)
    case alpha(_ message: String? = nil) // Only Letters
    case alphaNum(_ message: String? = nil)
    case alphaDash(_ message: String? = nil)
    case email(_ message: String? = nil)
    case numeric(_ message: String? = nil)
    case match(_ value: String, _ message: String? = nil)
    case unique(check: @Sendable (String) async -> Bool, _ message: String? = nil)
    case regex(_ pattern: String, _ message: String? = nil)
    case url(_ message: String? = nil)
    case digits(_ length: Int, _ message: String? = nil)
    case inList(_ values: [String], _ message: String? = nil)
}
