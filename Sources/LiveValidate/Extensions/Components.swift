//
//  Components.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 20/09/1447 AH.
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

extension DatePicker where Label == Text {
    @MainActor
    public init(_ titleKey: LocalizedStringKey, selection proxy: Validate<Date>.ValidationProxy, displayedComponents: DatePickerComponents = [.hourAndMinute, .date]) {
        self.init(titleKey, selection: proxy.binding, displayedComponents: displayedComponents)
    }

    @MainActor
    public init(_ title: String, selection proxy: Validate<Date>.ValidationProxy, displayedComponents: DatePickerComponents = [.hourAndMinute, .date]) {
        self.init(title, selection: proxy.binding, displayedComponents: displayedComponents)
    }
}

extension Toggle where Label == Text {
    @MainActor
    public init(_ titleKey: LocalizedStringKey, isOn proxy: Validate<Bool>.ValidationProxy) {
        self.init(titleKey, isOn: proxy.binding)
    }

    @MainActor
    public init(_ title: String, isOn proxy: Validate<Bool>.ValidationProxy) {
        self.init(title, isOn: proxy.binding)
    }
}
