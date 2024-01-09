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

class AppleSignViewController: NSObject, AuthController {
    typealias ControllerFactory = ([ASAuthorizationAppleIDRequest]) -> ASAuthorizationController
    
    let controllerFactory: ControllerFactory
    private var secureNonceProvider: SecureNonceProviding
    private let authSubject = PassthroughSubject<ASAuthorization, AuthError>()
    
    init(
        controllerFactory: @escaping ControllerFactory = ASAuthorizationController.init,
        secureNonceProvider: SecureNonceProviding = SecureNonceProvider()
    ) {
        self.controllerFactory = controllerFactory
        self.secureNonceProvider = secureNonceProvider
    }
    
    func authenticate() {
        let request = makeRequest()
        let controller = controllerFactory([request])
        controller.delegate = self
        controller.performRequests()
    }
    
    func makeRequest() -> ASAuthorizationAppleIDRequest {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = secureNonceProvider.generateNonce()
        return request
    }
}

extension AppleSignViewController: ASAuthorizationControllerDelegate {
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
