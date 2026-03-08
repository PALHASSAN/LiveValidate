//
//  ErrorMessage.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 17/09/1447 AH.
//

import SwiftUI

public struct ErrorMessage: View {
    let error: String?
    @State private var shakeEffect: CGFloat = 0
    
    public init<T>(_ proxy: Validate<T>.ValidationProxy) {
        self.error = proxy.error
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .modifier(Shake(animatableData: shakeEffect))
                    .onAppear {
                        withAnimation(.default) {
                            shakeEffect += 1
                        }
                    }
            }
        }
        .animation(.spring(), value: error)
    }
}
