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
    
    @Validate(.name("Username"), .required(), .between(3, 24))
    var username: String = ""
    
    @Validate(.name("Password"), .required(), .min(8), .max(24))
    var password: String = ""
    
    @Validate(.name("Birth Date"), .required(), .date(), .before(Date()))
    var birthDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Register Form") {
                    VStack(alignment: .leading) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                        ErrorMessage($email)
                    }
                    VStack(alignment: .leading) {
                        TextField("Username", text: $username)
                        ErrorMessage($username)
                    }
                    
                    VStack(alignment: .leading) {
                        TextField("Password", text: $password)
                        ErrorMessage($password)
                    }
                    
                    VStack(alignment: .leading) {
                        DatePicker("Birth date", selection: $birthDate, displayedComponents: .date)
                        ErrorMessage($birthDate)
                    }
                    
                    Button("Login") {
                        Task {
                            if await validateAll() {
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
