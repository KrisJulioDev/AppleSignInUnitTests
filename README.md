# Implementing Apple Sign In Unit Tests

Creating unit tests for Apple Sign In can present challenges due to several factors inherent in the authentication process and the associated APIs. Apple Sign In, aimed at enhancing user privacy and security, introduces complexities that make writing effective unit tests more challenging compared to typical functionalities. 

In this project, I will demonstrate you how to test the framework using the Adapter design pattern and Test Spy to mimic the process flow of Apple Sign in feature.

The process we will follow is the **GIVEN, WHEN, THEN** method.

Example 
 

GIVEN  
-----
```
let sut = AppleSignInController()
let spy = PublisherSpy(sut.authPublisher)
```

WHEN  
-----
```
sut.authenticate(.spy, nonce: "any nonce")
sut.didComplete(with: Credential(identityToken: Data("any".utf8),
                                 user: "user",
                                 fullName: PersonNameComponents()))
```
 
THEN  
-----
```
XCTAssertEqual(spy.events, [.finished])
```
 
