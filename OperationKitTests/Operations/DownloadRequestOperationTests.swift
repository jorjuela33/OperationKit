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

extension FileManager {
    
    func removeItemAt(_ url: URL) {
        do {
            try removeItem(at: url)
        } catch {}
    }
}

class DownloadRequestOperationTests: OperationKitTests {

    private let operationQueue = OperationKit.OperationQueue()
    
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
        let expectation = self.expectation(description: "download operation should get success response")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let cacheFile = cacheFolder.appendingPathComponent("\(NSUUID().uuidString).json")
        let downloadOperation = DownloadRequestOperation(request: request, cacheFile: cacheFile)
        let finishOperation = BlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(downloadOperation)
        operationQueue.addOperations([downloadOperation, finishOperation])
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(downloadOperation.response?.statusCode == 200)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheFile.path))
        
        defer {
            FileManager.default.removeItemAt(cacheFile)
        }
    }
    
    func testThatExecuteDownloadOperationWithCustomSessionConfigurationAndSuccessResponse() {
        /// given
        let expectation = self.expectation(description: "download operation should get success response with custom session")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let cacheFile = cacheFolder.appendingPathComponent("\(NSUUID().uuidString).json")
        let downloadOperation = DownloadRequestOperation(request: request, cacheFile: cacheFile)
        let finishOperation = BlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(downloadOperation)
        operationQueue.addOperations([downloadOperation, finishOperation])
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(downloadOperation.response?.statusCode == 200)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheFile.path))
        
        defer {
            FileManager.default.removeItemAt(cacheFile)
        }
    }
    
    func testThatExecuteDownloOperationShouldInvokeProgress() {
        /// given
        let expectation = self.expectation(description: "download operation should get success response")
        var isProgressInvoked = false
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let cacheFile = cacheFolder.appendingPathComponent("\(NSUUID().uuidString).json")
        let downloadOperation = DownloadRequestOperation(request: request, cacheFile: cacheFile)
        downloadOperation.downloadProgress { _ in
            isProgressInvoked = true
        }
        let finishOperation = BlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(downloadOperation)
        operationQueue.addOperations([downloadOperation, finishOperation])
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertTrue(downloadOperation.response?.statusCode == 200)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheFile.path))
        
        defer {
            FileManager.default.removeItemAt(cacheFile)
        }
    }
    
    func testThatDownloadOperationCancellation() {
        /// given
        let expectation = self.expectation(description: "download operation should get cancelled")
        var request = URLRequest(url: URL(string: "http://httpbin.org/get")!)
        request.httpMethod = HTTPMethod.GET.rawValue
        let cacheFile = cacheFolder.appendingPathComponent("\(NSUUID().uuidString).json")
        let downloadOperation = DownloadRequestOperation(request: request, cacheFile: cacheFile)
        let finishOperation = BlockOperation {
            expectation.fulfill()
        }
        
        /// when
        finishOperation.addDependency(downloadOperation)
        operationQueue.addOperations([downloadOperation, finishOperation])
        downloadOperation.cancel()
        
        /// then
        waitForExpectations(timeout: networkTimeout, handler: nil)
        XCTAssertNil(downloadOperation.response)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheFile.path))
        XCTAssertTrue(downloadOperation.isCancelled)
    }
}
