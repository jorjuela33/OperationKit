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
    
    let operationDidStartObserver: (Operation -> Void)?
    let operationDidProduceNewOperationObserver: ((Operation, NSOperation) -> Void)?
    let operationDidFinishObserver: ((Operation, [NSError]?) -> Void)?
    
    // MARK: Initialization
    
    init(operationDidStartObserver: (Operation -> Void)? = nil,
         operationDidProduceNewOperationObserver: ((Operation, NSOperation) -> Void)? = nil,
         operationDidFinishObserver: ((Operation, [NSError]?) -> Void)? = nil) {
        
        self.operationDidStartObserver = operationDidStartObserver
        self.operationDidProduceNewOperationObserver = operationDidProduceNewOperationObserver
        self.operationDidFinishObserver = operationDidFinishObserver
    }
    
    // MARK: ObservableOperation
    
    func operationDidStart(operation: Operation) {
        operationDidStartObserver?(operation)
    }
    
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        operationDidProduceNewOperationObserver?(operation, newOperation)
    }
    
    func operationDidFinish(operation: Operation, errors: [NSError]) {
        operationDidFinishObserver?(operation, errors)
    }
}

class UploadOperationTests: OperationKitTests {
    
    private let operationQueue = OperationQueue()
    
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
        let expectation = expectationWithDescription("upload operation should get success response")
        let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/post")!)
        request.HTTPMethod = HTTPMethod.POST.rawValue
        let uploadOperation = UploadOperation(request: request)
        let finishOperation = NSBlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(uploadOperation)
        operationQueue.addOperations([uploadOperation, finishOperation])
        
        /// then
        waitForExpectationsWithTimeout(networkTimeout, handler: nil)
        XCTAssertTrue(uploadOperation.response?.statusCode == 200)
        XCTAssertTrue(uploadOperation.data.length > 0)
    }
    
    func testThatExecuteUploadOperationWithCustomSessionConfigurationAndSuccessResponse() {
        /// given
        let expectation = expectationWithDescription("upload operation should get success response")
        let sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/post")!)
        request.HTTPMethod = HTTPMethod.POST.rawValue
        let uploadOperation = UploadOperation(request: request, sessionConfiguration: sessionConfiguration)
        let finishOperation = NSBlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(uploadOperation)
        operationQueue.addOperations([uploadOperation, finishOperation])
        
        /// then
        waitForExpectationsWithTimeout(networkTimeout, handler: nil)
        XCTAssertTrue(uploadOperation.response?.statusCode == 200)
        XCTAssertTrue(uploadOperation.data.length > 0)
    }
    
    func testThatUploadOperationCancellation() {
        /// given
        let expectation = expectationWithDescription("upload operation should get cancelled")
        let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/post")!)
        request.HTTPMethod = HTTPMethod.POST.rawValue
        let uploadOperation = UploadOperation(request: request)
        let finishOperation = NSBlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(uploadOperation)
        operationQueue.addOperations([uploadOperation, finishOperation])
        uploadOperation.cancel()
        
        /// then
        waitForExpectationsWithTimeout(networkTimeout, handler: nil)
        XCTAssertNil(uploadOperation.response)
        XCTAssertTrue(uploadOperation.cancelled)
    }
    
    func testThatUploadOperationShouldFailWithUnReachableHost() {
        /// given
        let expectation = expectationWithDescription("upload operation should fail")
        let sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let request = NSMutableURLRequest(URL: NSURL(string: "/post")!)
        request.HTTPMethod = HTTPMethod.POST.rawValue
        let uploadOperation = UploadOperation(request: request, sessionConfiguration: sessionConfiguration)
        var _errors: [NSError]?
        
        uploadOperation.addObserver(OperationTestObserver(operationDidFinishObserver: { operation, errors in
            _errors = errors
            expectation.fulfill()
        }))
        
        /// when
        operationQueue.addOperation(uploadOperation)
        
        /// then
        waitForExpectationsWithTimeout(networkTimeout, handler: nil)
        XCTAssertNil(uploadOperation.response)
        XCTAssertTrue(uploadOperation.data.length == 0)
        
        if let error = _errors?.first, conditionKey = error.userInfo[OperationConditionKey] as? String  {
            XCTAssertEqual(conditionKey, ReachabilityCondition.name)
        }
        else {
            XCTFail()
        }
    }
}
