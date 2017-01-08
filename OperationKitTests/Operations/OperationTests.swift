//
//  OperationTests.swift
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

private struct FailTestCondition: OperationCondition {
    
    // MARK: OperationCondition
    static var name = "test condition"
    
    public func dependency(for operation: OperationKit.Operation) -> Foundation.Operation? {
        return nil
    }
    
    func evaluate(for operation: OperationKit.Operation, completion: @escaping (OperationConditionResult) -> Void) {
        let error = NSError(domain: "", code: 0, userInfo: [OperationConditionKey: FailTestCondition.name])
        completion(.failed(error))
    }
}

private class TestOperation: OperationKit.Operation {
    
    // MARK: Overrided methods
    
    override func execute() {
        let operation = OperationKit.Operation()
        produceOperation(operation)
    }
}

class OperationTests: OperationKitTests {
    
    let operationQueue = OperationKit.OperationQueue()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatUserInitiated() {
        /// given
        let operation = OperationKit.Operation()
        
        /// when
        operation.userInitiated = true
        
        /// then
        XCTAssertTrue(operation.qualityOfService == .userInitiated)
    }
    
    func testThatOperationShouldCancelWithErrors() {
        /// given
        let expectation = self.expectation(description: "Operation should be cancelled")
        let operation = OperationKit.Operation()
        let error = NSError(domain: "", code: 0, userInfo: nil)
        var isSameError = false
        
        /// when
        operation.addObserver(OperationTestObserver(operationDidFinishObserver: { _, errors in
            isSameError = error === (errors?.first as? NSError)
            expectation.fulfill()
        }))
        
        operation.cancelWithError(error)
        operationQueue.addOperation(operation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(isSameError)
    }

    func testThatOperationShouldInvokeObserver() {
        /// given
        let expectation = self.expectation(description: "Operation should invoke observer")
        let operation = OperationKit.Operation()
        var invokedObserver = false
        
        /// when
        operation.addObserver(OperationTestObserver(operationDidFinishObserver: { _, errors in
            invokedObserver = true
            expectation.fulfill()
        }))
        
        operationQueue.addOperation(operation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(invokedObserver)
    }
    
    func testThatOperationShouldInvokeDidFinishMethodInObserver() {
        /// given
        let expectation = self.expectation(description: "Operation should invoke observer")
        let operation = OperationKit.Operation()
        var finishedOperation: OperationKit.Operation?
        
        /// when
        operation.addObserver(OperationTestObserver(operationDidFinishObserver: { op, errors in
            finishedOperation = op
            expectation.fulfill()
        }))
        
        operationQueue.addOperation(operation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(finishedOperation === operation)
    }
    
    func testThatOperationShouldInvokeDidStartMethodInObserver() {
        /// given
        let expectation = self.expectation(description: "Operation should invoke observer")
        let operation = OperationKit.Operation()
        var statedOperation: OperationKit.Operation?
        
        /// when
        operation.addObserver(OperationTestObserver(operationDidStartObserver: { op in
            statedOperation = op
            expectation.fulfill()
        }))
        
        operationQueue.addOperation(operation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(statedOperation === operation)
    }

    func testThatOperationShouldInvokeDidProduceOperationtMethodInObserver() {
        /// given
        let expectation = self.expectation(description: "Operation should invoke observer")
        let operation = TestOperation()
        var oldOperation: OperationKit.Operation?
        var producedOperation: Foundation.Operation?
        
        /// when
        operation.addObserver(OperationTestObserver(operationDidProduceNewOperationObserver: { op, newOp in
            oldOperation = op
            producedOperation = newOp
            expectation.fulfill()
        }))
        
        operationQueue.addOperation(operation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(oldOperation === oldOperation)
        XCTAssertNotNil(producedOperation)
    }
    
    func testThatOperationShouldFailForCondition() {
        /// given
        let expectation = self.expectation(description: "Operation should fail for condition")
        let operation = OperationKit.Operation()
        var failedForCondition = false
        
        /// when
        operation.addCondition(FailTestCondition())
        
        operation.addObserver(OperationTestObserver(operationDidFinishObserver: { _, errors in
            failedForCondition = (errors?.first as? NSError)?.userInfo[OperationConditionKey] as? String == FailTestCondition.name
            expectation.fulfill()
        }))
        
        operationQueue.addOperation(operation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(failedForCondition)
    }
    
    func testThatOperationShouldFailWithMultiplesErrors() {
        /// given
        let expectation = self.expectation(description: "Operation should fail")
        let operation = OperationKit.Operation()
        var failingConditions = 0
        
        /// when
        operation.addCondition(ReachabilityCondition(host: URL(string: "")!))
        operation.addCondition(FailTestCondition())
        operation.addCondition(FailTestCondition())
        
        operation.addObserver(OperationTestObserver(operationDidFinishObserver: { _, errors in
            failingConditions = errors?.count ?? 0
            expectation.fulfill()
        }))
        
        operationQueue.addOperation(operation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(failingConditions > 1)
    }
}
