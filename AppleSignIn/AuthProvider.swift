//
//  AuthProvider.swift
//  AppleSignIn
//
//  Created by Khristoffer Julio on 1/9/24.
//

import AuthenticationServices
import Combine

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

protocol SecureNonceProviding {
    var currentNonce: String { get }
    
    func generateNonce() -> String
}

class SecureNonceProvider: SecureNonceProviding {
    var currentNonce: String { "any raw" }
    
    func generateNonce() -> String {
        return "any encrypted"
    }
}

class AppleSignInController: NSObject { 
    private var secureNonceProvider: SecureNonceProviding
    private let authSubject = PassthroughSubject<ASAuthorization, AuthError>()
    
    init(secureNonceProvider: SecureNonceProviding = SecureNonceProvider()) {
        self.secureNonceProvider = secureNonceProvider
    }
    
    func authenticate(_ controller: ASAuthorizationController) {
        controller.delegate = self
        controller.performRequests()
    }
}

extension AppleSignInController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authSubject.send(completion: .failure(.underlying(error)))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authSubject.send(completion: .failure(.invalidCredentials))
            return
        }
//        authSubject.send(credential)
    }
}
