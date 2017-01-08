//
//  URLRequestOperationTests.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/8/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import XCTest
@testable import OperationKit

struct OperationTestObserver: ObservableOperation {
    
    let operationDidStartObserver: ((OperationKit.Operation) -> Void)?
    let operationDidProduceNewOperationObserver: ((OperationKit.Operation, Foundation.Operation) -> Void)?
    let operationDidFinishObserver: ((OperationKit.Operation, [Error]?) -> Void)?
    
    // MARK: Initialization
    
    init(operationDidStartObserver: ((OperationKit.Operation) -> Void)? = nil,
         operationDidProduceNewOperationObserver: ((OperationKit.Operation, Foundation.Operation) -> Void)? = nil,
         operationDidFinishObserver: ((OperationKit.Operation, [Error]?) -> Void)? = nil) {
        
        self.operationDidStartObserver = operationDidStartObserver
        self.operationDidProduceNewOperationObserver = operationDidProduceNewOperationObserver
        self.operationDidFinishObserver = operationDidFinishObserver
    }
    
    // MARK: ObservableOperation
    
    func operationDidStart(_ operation: OperationKit.Operation) {
        operationDidStartObserver?(operation)
    }
    
    func operation(_ operation: OperationKit.Operation, didProduceOperation newOperation: Foundation.Operation) {
        operationDidProduceNewOperationObserver?(operation, newOperation)
    }
    
    func operationDidFinish(_ operation: OperationKit.Operation, errors: [Error]) {
        operationDidFinishObserver?(operation, errors)
    }
}

class URLRequestOperationTests: OperationKitTests {
    
    fileprivate let operationQueue = OperationKit.OperationQueue()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatExecuteRequestOperationWithDefaultSessionAndSuccessResponse() {
        /// given
        let expectation = self.expectation(description: "URL Request operation should get success response")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let urlRequestOperation = URLRequestOperation(request: request)
        urlRequestOperation.completionBlock = {
            expectation.fulfill()
        }
        
        /// when
        operationQueue.addOperation(urlRequestOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(urlRequestOperation.response?.statusCode == 200)
    }
    
    func testThatExecuteRequestOperationWithCustomSessionConfigurationAndSuccessResponse() {
        /// given
        let expectation = self.expectation(description: "URL Request operation should get success response with custom session")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let urlRequestOperation = URLRequestOperation(request: request, sessionConfiguration: URLSessionConfiguration.ephemeral)
        urlRequestOperation.completionBlock = {
            expectation.fulfill()
        }

        /// when
        operationQueue.addOperation(urlRequestOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(urlRequestOperation.response?.statusCode == 200)
    }
}

extension URLRequestOperationTests {
    
    // MARK: Validation Tests
    
    func testThatURLRequestOperationDefaultStatusCodesValidationShouldPass() {
        /// given
        let expectation = self.expectation(description: "URL Request operation default status code validation should pass")
        var request = URLRequest(url: URL(string: "http://httpbin.org/status/200")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let urlRequestOperation = URLRequestOperation(request: request)
        var errorsShouldNotContainsUnacceptableStatusCodeFailure = false
        let operationObserver = OperationTestObserver { _, errors in
            errorsShouldNotContainsUnacceptableStatusCodeFailure = errors?.flatMap({ $0 as? OperationKitError }).filter({ $0.isUnacceptableStatusCode }).isEmpty == true
            expectation.fulfill()
        }
        
        /// when
        urlRequestOperation.addObserver(operationObserver)
        urlRequestOperation.validate()
        operationQueue.addOperation(urlRequestOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(errorsShouldNotContainsUnacceptableStatusCodeFailure)
    }
    
    func testThatURLRequestOperationCustomStatusCodesValidationShouldPass() {
        /// given
        let expectation = self.expectation(description: "URL Request operation custom status code validation should pass")
        var request = URLRequest(url: URL(string: "http://httpbin.org/status/404")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let urlRequestOperation = URLRequestOperation(request: request)
        var errorsShouldNotContainsUnacceptableStatusCodeFailure = false
        let operationObserver = OperationTestObserver { _, errors in
            errorsShouldNotContainsUnacceptableStatusCodeFailure = errors?.flatMap({ $0 as? OperationKitError }).filter({ $0.isUnacceptableStatusCode }).isEmpty == true
            expectation.fulfill()
        }
        
        /// when
        urlRequestOperation.addObserver(operationObserver)
        urlRequestOperation.validate(acceptableStatusCodes: Array(403..<405))
        operationQueue.addOperation(urlRequestOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(errorsShouldNotContainsUnacceptableStatusCodeFailure)
    }
    
    func testThatURLRequestOperationDefaultStatusCodesValidationShouldFail() {
        /// given
        let expectation = self.expectation(description: "URL Request operation default status code validation should fail")
        var request = URLRequest(url: URL(string: "http://httpbin.org/status/404")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let urlRequestOperation = URLRequestOperation(request: request)
        var errorsContainsUnacceptableStatusCodeFailure = false
        let operationObserver = OperationTestObserver { _, errors in
            errorsContainsUnacceptableStatusCodeFailure = errors?.flatMap({ $0 as? OperationKitError }).filter({ $0.isUnacceptableStatusCode }).isEmpty == false
            expectation.fulfill()
        }
        
        /// when
        urlRequestOperation.addObserver(operationObserver)
        urlRequestOperation.validate()
        operationQueue.addOperation(urlRequestOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(errorsContainsUnacceptableStatusCodeFailure)
    }
    
    func testThatURLRequestOperationCustomStatusCodesValidationShouldFail() {
        /// given
        let expectation = self.expectation(description: "URL Request operation custom status code validation should fail")
        var request = URLRequest(url: URL(string: "http://httpbin.org/status/200")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let urlRequestOperation = URLRequestOperation(request: request)
        var errorsContainsUnacceptableStatusCodeFailure = false
        let operationObserver = OperationTestObserver { _, errors in
            errorsContainsUnacceptableStatusCodeFailure = errors?.flatMap({ $0 as? OperationKitError }).filter({ $0.isUnacceptableStatusCode }).isEmpty == false
            expectation.fulfill()
        }
        
        /// when
        urlRequestOperation.addObserver(operationObserver)
        urlRequestOperation.validate(acceptableStatusCodes: Array(300..<301))
        operationQueue.addOperation(urlRequestOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(errorsContainsUnacceptableStatusCodeFailure)
    }
}
