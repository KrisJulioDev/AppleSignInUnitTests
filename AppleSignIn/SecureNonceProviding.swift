//
//  SecureNonceProviding.swift
//  AppleSignIn
//
//  Created by Khristoffer Julio on 1/9/24.
//
 
struct Nonce {
    let raw: String
    let sha256: String
}

protocol SecureNonceProviding {
    func generateNonce() -> Nonce
}
