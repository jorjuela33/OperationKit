//
//  DownloadOperationTests.swift
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

extension NSFileManager {
    
    func removeItemAt(URL: NSURL) {
        do {
            try removeItemAtURL(URL)
        } catch {}
    }
}

class DownloadOperationTests: OperationKitTests {

    private let operationQueue = OperationQueue()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatExecuteDownloOperationWithDefaultSessionAndSuccessResponse() {
        /// given
        let expectation = expectationWithDescription("download operation should get success response")
        let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/get")!)
        request.HTTPMethod = HTTPMethod.GET.rawValue
        let cacheFile = cacheFolder.URLByAppendingPathComponent("\(rand()).json")
        let downloadOperation = DownloadOperation(request: request, cacheFile: cacheFile)
        let finishOperation = NSBlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(downloadOperation)
        operationQueue.addOperations([downloadOperation, finishOperation])
        
        /// then
        waitForExpectationsWithTimeout(networkTimeout, handler: nil)
        XCTAssertTrue(downloadOperation.response?.statusCode == 200)
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(cacheFile.path!))
        
        defer {
            NSFileManager.defaultManager().removeItemAt(cacheFile)
        }
    }
    
    func testThatExecuteDownloadOperationWithCustomSessionConfigurationAndSuccessResponse() {
        /// given
        let expectation = expectationWithDescription("download operation should get success response with custom session")
        let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/get")!)
        request.HTTPMethod = HTTPMethod.GET.rawValue
        let cacheFile = cacheFolder.URLByAppendingPathComponent("\(rand()).json")
        let downloadOperation = DownloadOperation(request: request, cacheFile: cacheFile)
        let finishOperation = NSBlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(downloadOperation)
        operationQueue.addOperations([downloadOperation, finishOperation])
        
        /// then
        waitForExpectationsWithTimeout(networkTimeout, handler: nil)
        XCTAssertTrue(downloadOperation.response?.statusCode == 200)
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(cacheFile.path!))
        
        defer {
            NSFileManager.defaultManager().removeItemAt(cacheFile)
        }
    }
    
    func testThatDownloadOperationCancellation() {
        /// given
        let expectation = expectationWithDescription("download operation should get cancelled")
        let request = NSMutableURLRequest(URL: NSURL(string: "http://httpbin.org/get")!)
        request.HTTPMethod = HTTPMethod.GET.rawValue
        let cacheFile = cacheFolder.URLByAppendingPathComponent("\(rand()).json")
        let downloadOperation = DownloadOperation(request: request, cacheFile: cacheFile)
        let finishOperation = NSBlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(downloadOperation)
        operationQueue.addOperations([downloadOperation, finishOperation])
        downloadOperation.cancel()
        
        /// then
        waitForExpectationsWithTimeout(networkTimeout, handler: nil)
        XCTAssertNil(downloadOperation.response)
        XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(cacheFile.path!))
        XCTAssertTrue(downloadOperation.cancelled)
    }
}
