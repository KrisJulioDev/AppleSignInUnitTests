//
//  AuthProvider.swift
//  AppleSignIn
//
//  Created by Khristoffer Julio on 1/9/24.
//

import AuthenticationServices
import Combine

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
