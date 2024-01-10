//
//  AppleSignInController.swift
//  AppleSignIn
//
//  Created by Khristoffer Julio on 1/10/24.
//
 
import AuthenticationServices
import Combine
 
class AppleSignInController: NSObject {
    private var secureNonceProvider: SecureNonceProviding
    private(set) var currentNonce: String?
    
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
