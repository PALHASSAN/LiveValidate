//
//  RegistrationViewModel.swift
//  LiveValidate
//
//  Created by Alhassan AlMakki on 16/09/1447 AH.
//

import Foundation

@MainActor
@Observable
class RegistrationViewModel {
    
    struct LaravelResponse: Codable {
        let available: Bool
    }
    
    func checkEmailUnique(_ email: String) async -> Bool {
        guard let url = URL(string: "http://172.20.10.8:8000/api/check-email") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let rawResponse = String(data: data, encoding: .utf8) ?? "رد فارغ"
            print("📦 رد لارافيل الخام: \(rawResponse)")
            
            let decoded = try JSONDecoder().decode(LaravelResponse.self, from: data)
            return decoded.available
            
        } catch {
            print("❌ خطأ سويفت: \(error.localizedDescription)")
            return false
        }
    }
}
