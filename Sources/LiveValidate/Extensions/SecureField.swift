//
//  SecureField.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 16/09/1447 AH.
//

import SwiftUI

extension SecureField where Label == Text {
    @MainActor
    public init(_ titleKey: LocalizedStringKey, text proxy: Validate.ValidationProxy) {
        self.init(titleKey, text: proxy.binding)
    }
}
