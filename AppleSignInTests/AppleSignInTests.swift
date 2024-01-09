//
//  AppleSignInTests.swift
//  AppleSignInTests
//
//  Created by Khristoffer Julio on 1/9/24.
//

import AuthenticationServices
import XCTest

@testable import AppleSignIn

final class AppleSignInTests: XCTestCase {
    func test_authenticate_performsProperRequest() {
        let nonceProvider = ConstantNonceProvider()
        let nonce = nonceProvider.generateNonce()
        
        let spy = ASAuthorizationController.spy
        var receivedRequest = [ASAuthorizationAppleIDRequest]()
        
        let sut = AppleSignViewController(controllerFactory: { requests in
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
