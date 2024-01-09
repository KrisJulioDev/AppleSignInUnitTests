//
//  AppleSignInTests.swift
//  AppleSignInTests
//
//  Created by Khristoffer Julio on 1/9/24.
//

import AuthenticationServices
import XCTest
import Combine

@testable import AppleSignIn

final class AppleSignInControllerAdapterTests: XCTestCase {
    func test_authenticate_performsProperRequest() {
        let controller = AppleSignInControllerSpy()
        let nonceProvider = ConstantNonceProvider()
        let nonce = nonceProvider.generateNonce().sha256
        
        let sut = AppleSignInControllerAdapter(controller: controller, nonce: nonceProvider)
        sut.authenticate()
        
        XCTAssertEqual(controller.requests.count, 1, "request nonce")
        XCTAssertEqual(controller.requests.first?.requestedScopes, [.fullName, .email], "request scopes")
        XCTAssertEqual(controller.requests.first?.nonce, nonce, "request nonce")
    }
    
    private class AppleSignInControllerSpy: AppleSignInController {
        var requests = [ASAuthorizationAppleIDRequest]()
        
        override func authenticate(_ controller: ASAuthorizationController, nonce: String) {
            requests += controller.authorizationRequests.compactMap {
                $0 as? ASAuthorizationAppleIDRequest
            }
        }
    }
}

final class AppleSignInControllerTests: XCTestCase {
    func test_authenticate_performsProperRequest() {
        let spy = ASAuthorizationController.spy
        let sut = AppleSignInController()
        sut.authenticate(spy, nonce: "any")
         
        XCTAssertTrue(spy.delegate === sut, "sut is delegate")
        XCTAssertEqual(spy.performRequestsCallCount, 1, "perform request call count")
    }
    
    func test_didCompleteWithError_emitsFailure() {
        let sut = AppleSignInController()
        sut.authorizationController(controller: .spy, didCompleteWithError: NSError(domain: "error", code: 0))
        
        var receivedError: Error?
        var cancellable: AnyCancellable?
        cancellable = sut.authSubject.sink { completion in
            switch completion {
            case let .failure(error):
                receivedError = error
            case .finished:
                XCTFail("Expects receiving error")
            }
        } receiveValue: { _ in
            XCTFail("Expects receiving error")
        }
        
        XCTAssertNotNil(receivedError)
        cancellable?.cancel()
    }
}

private class ConstantNonceProvider: SecureNonceProvider {
    override func generateNonce() -> Nonce {
        return Nonce(raw: "raw", sha256: "sha256")
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
