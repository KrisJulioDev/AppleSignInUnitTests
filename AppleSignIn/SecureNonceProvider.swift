//
//  SecureNonceProvider.swift
//  AppleSignIn
//
//  Created by Khristoffer Julio on 1/9/24.
//
import CryptoKit
import Foundation

class SecureNonceProvider: SecureNonceProviding {
    func generateNonce() -> Nonce {
        let rawNonce = randomNonceString()
        let sha256 = sha256(of: rawNonce)
        return Nonce(raw: rawNonce, sha256: sha256)
    }
      
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0, "Invalid nonce length")
         
        var data = Data(count: length)
        data.withUnsafeMutableBytes { buffer in
            guard let mutableBytes = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return
            }
            _ = SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
        }
          
        return data.map { String(format: "%02hhx", $0) }.joined()
    }

    
    private func sha256(of string: String) -> String {
        if let data = string.data(using: .utf8) {
            let hashed = SHA256.hash(data: data)
            let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
            return hashString
        }
        return ""
    }
}
