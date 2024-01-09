//
//  AppleSignInTests.swift
//  AppleSignInTests
//
//  Created by Khristoffer Julio on 1/9/24.
//

import AuthenticationServices
import XCTest

@testable import AppleSignIn

class AppleSignInControllerAdapter: AuthController {
    let controller: AppleSignInController
    let nonceProvider: SecureNonceProvider
    
    init(controller: AppleSignInController, nonce: SecureNonceProvider) {
        self.controller = controller
        self.nonceProvider = nonce
    }
    
     func authenticate() {
        let request = makeRequest()
        let authController = ASAuthorizationController(authorizationRequests: [request])
        controller.authenticate(authController)
    }
    
    func makeRequest() -> ASAuthorizationAppleIDRequest {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonceProvider.generateNonce()
        return request
    }
}

class AppleSignInControllerAdapterTests: XCTestCase {
    func test_authenticate_performsProperRequest() {
        let controller = AppleSignInControllerSpy()
        let nonceProvider = ConstantNonceProvider()
        let nonce = nonceProvider.generateNonce()
        
        let sut = AppleSignInControllerAdapter(controller: controller, nonce: nonceProvider)
        sut.authenticate()
        
        XCTAssertEqual(controller.requests.count, 1, "request nonce")
        XCTAssertEqual(controller.requests.first?.requestedScopes, [.fullName, .email], "request scopes")
        XCTAssertEqual(controller.requests.first?.nonce, nonce, "request nonce")
    }
    
    private class AppleSignInControllerSpy: AppleSignInController {
        var requests = [ASAuthorizationAppleIDRequest]()
        
        override func authenticate(_ controller: ASAuthorizationController) {
            requests += controller.authorizationRequests.compactMap {
                $0 as? ASAuthorizationAppleIDRequest
            }
        }
    }
}

final class AppleSignInTests: XCTestCase {
    func test_authenticate_performsProperRequest() {
        let nonceProvider = ConstantNonceProvider()
        let nonce = nonceProvider.generateNonce()
        
        let spy = ASAuthorizationController.spy
        var receivedRequest = [ASAuthorizationAppleIDRequest]()
        
        let sut = AppleSignInController(controllerFactory: { requests in
            receivedRequest += requests
            return spy
        }, secureNonceProvider: nonceProvider)
         
        sut.authenticate()
        
        XCTAssertEqual(receivedRequest.first?.nonce, nonce, "request nonce")
        XCTAssertEqual(receivedRequest.first?.requestedScopes, [.fullName, .email], "request scopes")
        XCTAssertEqual(receivedRequest.count, 1, "request count")
        XCTAssertTrue(spy.delegate === sut, "sut is delegate")
        XCTAssertEqual(spy.performRequestsCallCount, 1, "perform request call count")
    }
}

private class ConstantNonceProvider: SecureNonceProvider {
    override var currentNonce: String { "any raw" }
    
    override func generateNonce() -> String {
        return "any encrypted"
    }
}

extension ASAuthorizationController {
    static var spy: Spy {
        let dummyRequest = ASAuthorizationAppleIDProvider().createRequest()
        return Spy(authorizationRequests: [dummyRequest])
    }

    class Spy: ASAuthorizationController {
        
        private(set) var performRequestsCallCount = 0
        
        override func performRequests() {
            performRequestsCallCount += 1
        }
    }
}
