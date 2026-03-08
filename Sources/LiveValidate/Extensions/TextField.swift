//
//  TextField.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 16/09/1447 AH.
//

import SwiftUI

extension TextField where Label == Text {
    @MainActor
    public init<T>(_ titleKey: LocalizedStringKey, text proxy: Validate<T>.ValidationProxy) where T: LosslessStringConvertible {
        let bridgeBinding = Binding<String>(
            get: { "\(proxy.binding.wrappedValue)" },
            set: { newValue in
                if let value = T(newValue) {
                    proxy.binding.wrappedValue = value
                }
            }
        )
        
        self.init(text: bridgeBinding, label: { Text(titleKey) })
    }
    
    @MainActor
    public init<T>(_ title: String, text proxy: Validate<T>.ValidationProxy) where T: LosslessStringConvertible {
        let bridgeBinding = Binding<String>(
            get: { "\(proxy.binding.wrappedValue)" },
            set: { if let value = T($0) { proxy.binding.wrappedValue = value } }
        )
        self.init(text: bridgeBinding, label: { Text(title) })
    }
}
