//
//  TestView.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 16/09/1447 AH.
//

import SwiftUI

struct TestView: View {
    @Validate(.name("Email"), .required(), .email(), .unique(table: "users", column: "email"))
    var email: String = ""
    
    @Validate(.name("Phone Number"), .required(), .regex("^05[0-9]{8}$"))
    var phone: String = ""
    
    @Validate(.name("OTP"), .digits(4))
    var otp: Int = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Login Form") {
                    VStack(alignment: .leading) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                        ErrorMessage($email)
                    }
                    VStack(alignment: .leading) {
                        TextField("Phone number (05xxxxxxxx)", text: $phone)
                        ErrorMessage($phone)
                    }
                    
                    VStack(alignment: .leading) {
                        TextField("OTP code", text: $otp)
                        ErrorMessage($otp)
                    }
                    Button("Login") {
                        Task {
                            if await validateOnly($phone, $email) {
                                print("Welcome Back!")
                            }
                        }
                    }
                }
            }
            .navigationTitle("SWIFT Live Validate")
        }
    }
}

#Preview {
//    let _ = ValidateConfig.setup(engine: .api(url: "http://172.20.10.8:8000/api/check-email"))
//    let _ = ValidateConfig.setup(engine: .swiftData(container: sharedModelContainer)))
    TestView()
}
