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

class AppleSignInController: NSObject {
    private var secureNonceProvider: SecureNonceProviding
    public let authSubject = PassthroughSubject<ASAuthorization, AuthError>()
    
    init(secureNonceProvider: SecureNonceProviding = SecureNonceProvider()) {
        self.secureNonceProvider = secureNonceProvider
    }
    
    func authenticate(_ controller: ASAuthorizationController, nonce: String) {
        controller.delegate = self
        controller.performRequests()
    }
}

extension AppleSignInController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authSubject.send(completion: .failure(.invalidCredentials))
            return
        }
//        authSubject.send(credential)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authSubject.send(completion: .failure(.underlying(error)))
    }
}
