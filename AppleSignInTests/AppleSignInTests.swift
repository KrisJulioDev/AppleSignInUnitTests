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
        let spy = PublisherSpy(sut.authPublisher)
        
        sut.authorizationController(controller: .spy, didCompleteWithError: NSError(domain: "error", code: 0))
        
        XCTAssertEqual(spy.events, [.error])
    }
    
    func test_didCompleteWithCredential_withInvalidToken_emitsFailure() {
        let sut = AppleSignInController()
        let spy = PublisherSpy(sut.authPublisher)
        
        sut.authenticate(.spy, nonce: "any nonce")
        sut.didComplete(with: Credential(identityToken: nil,
                                         user: "user",
                                         fullName: PersonNameComponents()))
        
        XCTAssertEqual(spy.events, [.error])
    }
    
    func test_didCompleteWithCredential_withoutNonce_emitsFailure() {
        let sut = AppleSignInController()
        let spy = PublisherSpy(sut.authPublisher)
        
        sut.didComplete(with: Credential(identityToken: Data("any".utf8),
                                         user: "user",
                                         fullName: PersonNameComponents()))
        
        XCTAssertEqual(spy.events, [.error])
    }
    
    func test_didCompleteWithCredential_withValidCredential_emitsSuccess() {
        let sut = AppleSignInController()
        let spy = PublisherSpy(sut.authPublisher)
        
        sut.authenticate(.spy, nonce: "any nonce")
        sut.didComplete(with: Credential(identityToken: Data("any".utf8),
                                         user: "user",
                                         fullName: PersonNameComponents()))
        
        XCTAssertEqual(spy.events, [.finished])
    }
    
}

extension AppleSignInControllerTests {
    private struct Credential: AppleIDCredential {
        let identityToken: Data?
        let user: String
        let fullName: PersonNameComponents?
    }
    
    private class PublisherSpy<Success, Failure: Error> {
        private var cancellable: Cancellable? = nil
        private(set) var events: [Event] = []
        
        enum Event {
            case value
            case finished
            case error
        }
        
        init(_ publisher: AnyPublisher<Success, Failure>) {
            cancellable = publisher.sink { completion in
                switch completion {
                case .failure:
                    self.events.append(.error)
                case .finished:
                    self.events.append(.finished)
                }
            } receiveValue: { _ in
                self.events.append(.value)
            }
            
        }
    }
    
    private class ConstantNonceProvider: SecureNonceProvider {
        override func generateNonce() -> Nonce {
            return Nonce(raw: "raw", sha256: "sha256")
        }
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
