//
//  ViewExtension.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 20/09/1447 AH.
//
import SwiftUI

public extension View {
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
//        let mirror = Mirror(reflecting: self)
//        let customMsgs = extractValidationMessages(from: mirror)
        
        for field in fields {
//            field.setCustomMessages(customMsgs, name: "")
            
            if await !field.checkIsValid() {
                isFormValid = false
            }
        }
        
        return isFormValid
    }
    
//    @MainActor
//    func prepareLiveValidation() {
//        let mirror = Mirror(reflecting: self)
//        let customMsgs = extractValidationMessages(from: mirror)
//        
//        for child in mirror.children {
//            if let field = child.value as? any ValidatableField {
//                let propertyName = child.label?.replacingOccurrences(of: "_", with: "") ?? ""
//                field.setCustomMessages(customMsgs, name: propertyName)
//            }
//        }
//    }
    
//    private func extractValidationMessages(from mirror: Mirror) -> [String: String] {
//        for child in mirror.children {
//            if child.label == "validationMessages", let dict = child.value as? [String: String] {
//                return dict
//            }
//        }
//        return [:]
//    }
}
