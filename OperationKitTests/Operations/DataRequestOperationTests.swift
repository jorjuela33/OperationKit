//
//  DataRequestOperationTests.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/9/17.
//  Copyright © 2017 Chessclub. All rights reserved.
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

class DataRequestOperationTests: OperationKitTests {
    
    fileprivate let operationQueue = OperationKit.OperationQueue()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatExecuteDataRequestOperationWithDefaultSessionAndSuccessResponse() {
        /// given
        let expectation = self.expectation(description: "Data Request operation should get success response and data")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let dataRequestOperation = DataRequestOperation(request: request, sessionConfiguration: URLSessionConfiguration.default)
        dataRequestOperation.completionBlock = {
            expectation.fulfill()
        }
        
        /// when
        operationQueue.addOperation(dataRequestOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(dataRequestOperation.response?.statusCode == 200)
        XCTAssertGreaterThan(dataRequestOperation.data.count, 0)
    }
    
    func testThatExecuteURLRequestOperationWithCustomSessionConfigurationAndSuccessResponse() {
        /// given
        let expectation = self.expectation(description: "Data Request operation should get success response and data with custom session")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let dataRequestOperation = DataRequestOperation(request: request, sessionConfiguration: URLSessionConfiguration.default)
        dataRequestOperation.completionBlock = {
            expectation.fulfill()
        }
        
        /// when
        operationQueue.addOperation(dataRequestOperation)
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(dataRequestOperation.response?.statusCode == 200)
        XCTAssertGreaterThan(dataRequestOperation.data.count, 0)
    }
}
