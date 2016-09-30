//
//  UploadOperationTests.swift
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

class UploadOperationTests: OperationKitTests {
    
    private let operationQueue = OperationKit.OperationQueue()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatExecuteUploadOperationWithDefaultSessionAndSuccessResponse() {
        /// given
        let expectation = self.expectation(description: "upload operation should get success response")
        var request = URLRequest(url: URL(string: "http://httpbin.org/post")!)
        request.httpMethod = HTTPMethod.POST.rawValue
        let uploadOperation = UploadOperation(request: request)
        let finishOperation = BlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(uploadOperation)
        operationQueue.addOperations([uploadOperation, finishOperation])
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(uploadOperation.response?.statusCode == 200)
        XCTAssertTrue(uploadOperation.data.count > 0)
    }
    
    func testThatExecuteUploadOperationWithCustomSessionConfigurationAndSuccessResponse() {
        /// given
        let expectation = self.expectation(description: "upload operation should get success response")
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        var request = URLRequest(url: URL(string: "http://httpbin.org/post")!)
        request.httpMethod = HTTPMethod.POST.rawValue
        let uploadOperation = UploadOperation(request: request, sessionConfiguration: sessionConfiguration)
        let finishOperation = BlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(uploadOperation)
        operationQueue.addOperations([uploadOperation, finishOperation])
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(uploadOperation.response?.statusCode == 200)
        XCTAssertTrue(uploadOperation.data.count > 0)
    }
    
    func testThatUploadOperationCancellation() {
        /// given
        let expectation = self.expectation(description: "upload operation should get cancelled")
        var request = URLRequest(url: URL(string: "http://httpbin.org/post")!)
        request.httpMethod = HTTPMethod.POST.rawValue
        let uploadOperation = UploadOperation(request: request)
        let finishOperation = BlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(uploadOperation)
        operationQueue.addOperations([uploadOperation, finishOperation])
        uploadOperation.cancel()
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertNil(uploadOperation.response)
        XCTAssertTrue(uploadOperation.isCancelled)
    }
    
    func testThatUploadOperationShouldFailWithUnReachableHost() {
        /// given
        let expectation = self.expectation(description: "upload operation should fail")
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        var request = URLRequest(url: URL(string: "/post")!)
        request.httpMethod = HTTPMethod.POST.rawValue
        let uploadOperation = UploadOperation(request: request, sessionConfiguration: sessionConfiguration)
        var _errors: [Error]?
        
        uploadOperation.addObserver(OperationTestObserver(operationDidFinishObserver: { operation, errors in
            _errors = errors
            expectation.fulfill()
        }))
        
        /// when
        operationQueue.addOperation(uploadOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertNil(uploadOperation.response)
        XCTAssertTrue(uploadOperation.data.count == 0)
        
        if let error = _errors?.first as? NSError, let conditionKey = error.userInfo[OperationConditionKey] as? String  {
            XCTAssertEqual(conditionKey, ReachabilityCondition.name)
        }
        else {
            XCTFail()
        }
    }
}
