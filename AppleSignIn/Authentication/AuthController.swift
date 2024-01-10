//
//  AuthController.swift
//  AppleSignIn
//
//  Created by Khristoffer Julio on 1/10/24.
// 

protocol AuthController {
    func authenticate()
}

enum AuthError: Error {
    case invalidCredentials
    case underlying(Error)
}

enum AuthState {
    case failed(AuthError)
    case success
}
