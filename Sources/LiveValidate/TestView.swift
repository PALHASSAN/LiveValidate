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
    var otp: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Login Form") {
                    VStack(alignment: .leading) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                        ErrorMessage($email.error)
                    }
                    VStack(alignment: .leading) {
                        TextField("Phone number (05xxxxxxxx)", text: $phone)
                        if let error = $phone.error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        TextField("OTP code", text: $otp)
                        if let error = $otp.error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("SWIFT Live Validate")
        }
    }
    
    
    //    @State var vm = RegistrationViewModel()
    //
//        @Validate(
//            .required(),
//            .email(),
//            .unique(check: { value in
//                await RegistrationViewModel().checkEmailUnique(value)
//            }, "Email already used. ❌")
//        )
    //    var email: String = ""
    //
    //    var body: some View {
    //        Form {
    //            Section("Email Address") {
    //                TextField("Emal", text: $email)
    //                    .autocapitalization(.none)
    //
    //                if let error = $email.error {
    //                    Text(error)
    //                        .foregroundColor(.red)
    //                        .font(.caption)
    //                }
    //            }
    //        }
    //    }
}

#Preview {
//    let _ = ValidateConfig.setup(engine: .api(url: "http://yourapilink/"))
//    let _ = ValidateConfig.setup(engine: .swiftData(container: yourSwiftTable)))
    TestView()
}
