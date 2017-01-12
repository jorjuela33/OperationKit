//
//  URLRequestOperationTests.swift
//
//  Copyright © 2016. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import XCTest
@testable import OperationKit

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
    
    func testThatExecuteURLRequestOperationWithDefaultSessionAndSuccessResponse() {
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
    
    func testThatExecuteURLRequestOperationWithCustomSessionConfigurationAndSuccessResponse() {
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
    
    func testThatExecuteURLRequestOperationShouldInvokeDidSuspendAndResumeDelegate() {
        /// given
        let expectation = self.expectation(description: "URL Request operation should invoke did suspend and resume delegate")
        var didResumeWasInvoked = false
        var didSuspendWasInvoked = false
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let urlRequestOperation = URLRequestOperation(request: request)
        urlRequestOperation.completionBlock = {
            expectation.fulfill()
        }
        
        let operationObserver = OperationTestObserver(operationDidResumeObserver: { _ in
            didResumeWasInvoked = true
        }, operationDidSuspendObserver: { _ in
            didSuspendWasInvoked = true
        })
        
        /// when
        urlRequestOperation.addObserver(operationObserver)
        operationQueue.addOperation(urlRequestOperation)
        urlRequestOperation.suspend()
        urlRequestOperation.resume()
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(didResumeWasInvoked)
        XCTAssertTrue(didSuspendWasInvoked)
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
        let operationObserver = OperationTestObserver(operationDidFinishObserver: { _, errors in
            errorsShouldNotContainsUnacceptableStatusCodeFailure = errors?.flatMap({ $0 as? OperationKitError }).filter({ $0.isUnacceptableStatusCode }).isEmpty == true
            expectation.fulfill()
        })
        
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
        let operationObserver = OperationTestObserver (operationDidFinishObserver: { _, errors in
            errorsShouldNotContainsUnacceptableStatusCodeFailure = errors?.flatMap({ $0 as? OperationKitError }).filter({ $0.isUnacceptableStatusCode }).isEmpty == true
            expectation.fulfill()
        })
        
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
        let operationObserver = OperationTestObserver(operationDidFinishObserver: { _, errors in
            errorsContainsUnacceptableStatusCodeFailure = errors?.flatMap({ $0 as? OperationKitError }).filter({ $0.isUnacceptableStatusCode }).isEmpty == false
            expectation.fulfill()
        })
        
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
        let operationObserver = OperationTestObserver(operationDidFinishObserver: { _, errors in
            errorsContainsUnacceptableStatusCodeFailure = errors?.flatMap({ $0 as? OperationKitError }).filter({ $0.isUnacceptableStatusCode }).isEmpty == false
            expectation.fulfill()
        })
        
        /// when
        urlRequestOperation.addObserver(operationObserver)
        urlRequestOperation.validate(acceptableStatusCodes: Array(300..<301))
        operationQueue.addOperation(urlRequestOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(errorsContainsUnacceptableStatusCodeFailure)
    }
}
