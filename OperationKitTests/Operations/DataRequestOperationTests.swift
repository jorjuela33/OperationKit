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
        let dataRequestOperation = DataRequestOperation(request: request)
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
    
    func testThatExecuteDataRequestOperationWithCustomSessionConfigurationAndSuccessResponse() {
        /// given
        let expectation = self.expectation(description: "Data Request operation should get success response and data with custom session")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let dataRequestOperation = DataRequestOperation(request: request, sessionConfiguration: URLSessionConfiguration.ephemeral)
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

extension DataRequestOperationTests {
    
    // MARK: Response Tests
    
    func testThatExecuteDataRequestOperationWithDataResponse() {
        /// given
        let expectation = self.expectation(description: "Data Request operation should get a data response")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let dataRequestOperation = DataRequestOperation(request: request)
        var error: Error?
        var response: Data?
        dataRequestOperation.completionBlock = {
            expectation.fulfill()
        }
        
        /// when
        operationQueue.addOperation(dataRequestOperation)
        dataRequestOperation.responseData { result in
            switch result {
            case let .success(responseData):
                response = responseData
                
            case let .failure(_error):
                error = _error
            }
        }
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        guard let responseData = response else {
            XCTFail()
            return
        }
        
        XCTAssertGreaterThan(responseData.count, 0)
        XCTAssertNil(error)
    }
    
    func testThatExecuteDataRequestOperationWithJSONResponse() {
        /// given
        let expectation = self.expectation(description: "Data Request operation should get a JSON response")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let dataRequestOperation = DataRequestOperation(request: request)
        var error: Error?
        var response: Any?
        dataRequestOperation.completionBlock = {
            expectation.fulfill()
        }
        
        /// when
        operationQueue.addOperation(dataRequestOperation)
        dataRequestOperation.responseJSON { result in
            switch result {
            case let .success(responseJSON):
                response = responseJSON
                
            case let .failure(_error):
                error = _error
            }
        }
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        guard let responseJSON = response as? [String: Any] else {
            XCTFail()
            return
        }
        
        XCTAssertFalse(responseJSON.isEmpty)
        XCTAssertNil(error)
    }
    
    func testThatExecuteDataRequestOperationWithStringResponse() {
        /// given
        let expectation = self.expectation(description: "Data Request operation should get a string response")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let dataRequestOperation = DataRequestOperation(request: request)
        var error: Error?
        var response: String?
        dataRequestOperation.completionBlock = {
            expectation.fulfill()
        }
        
        /// when
        operationQueue.addOperation(dataRequestOperation)
        dataRequestOperation.responseString { result in
            switch result {
            case let .success(string):
                response = string
                
            case let .failure(_error):
                error = _error
            }
        }
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        guard let responseString = response else {
            XCTFail()
            return
        }
        
        XCTAssertFalse(responseString.isEmpty)
        XCTAssertNil(error)
    }
}
