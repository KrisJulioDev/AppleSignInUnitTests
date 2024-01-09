//
//  AppSignInControllerAdapter.swift
//  AppleSignIn
//
//  Created by Khristoffer Julio on 1/9/24.
//

import Foundation
import AuthenticationServices

class AppleSignInControllerAdapter: AuthController {
    let controller: AppleSignInController
    let nonceProvider: SecureNonceProvider
    
    init(controller: AppleSignInController, nonce: SecureNonceProvider) {
        self.controller = controller
        self.nonceProvider = nonce
    }
    
     func authenticate() {
         let nonce = nonceProvider.generateNonce()
         let request = makeRequest(nonce: nonce.sha256)
         let authController = ASAuthorizationController(authorizationRequests: [request])
         controller.authenticate(authController, nonce: nonce.raw)
    }
    
    func makeRequest(nonce: String) -> ASAuthorizationAppleIDRequest {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce
        return request
    }
}
