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
    private var currentNonce: String?
    
    public let authSubject = PassthroughSubject<ASAuthorization, AuthError>()
    var authPublisher: AnyPublisher<ASAuthorization, AuthError> {
        authSubject.eraseToAnyPublisher()
    }
    
    init(secureNonceProvider: SecureNonceProviding = SecureNonceProvider()) {
        self.secureNonceProvider = secureNonceProvider
    }
    
    func authenticate(_ controller: ASAuthorizationController, nonce: String) {
        currentNonce = nonce
        controller.delegate = self
        controller.performRequests()
    }
}

protocol AppleIDCredential {
    var identityToken: Data? { get }
    var user: String { get }
    var fullName: PersonNameComponents? { get }
}

extension ASAuthorizationAppleIDCredential: AppleIDCredential {}

extension AppleSignInController: ASAuthorizationControllerDelegate {
    func didComplete(with credentials: AppleIDCredential) {
        guard
            let appleIDToken = credentials.identityToken,
            let identityTokenString = String(data: appleIDToken, encoding: .utf8),
            let nonce = currentNonce
        else {
            authSubject.send(completion: .failure(.invalidCredentials))
            return
        }
        
        // do whatever you need for token and nonce
        // send to firebase for next step registration/login
        
        authSubject.send(completion: .finished)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let credential = authorization.credential as? AppleIDCredential
        credential.map(didComplete)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authSubject.send(completion: .failure(.underlying(error)))
    }
}
