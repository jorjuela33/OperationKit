//
//  TimeoutObserver.swift
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

import Foundation

public struct TimeoutObserver: ObservableOperation {
    
    public static let timeoutKey = "Timeout"
    
    private let timeout: TimeInterval
    
    // MARK: Initialization
    
    public init(timeout: TimeInterval = 30) {
        self.timeout = timeout
    }
    
    // MARK: OperationObserver
    
    public func operationDidStart(_ operation: Operation) {
        // When the operation starts, queue up a block to cause it to time out.
        let when = DispatchTime.now() + Double(Int64(timeout * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).asyncAfter(deadline: when) {
            if !operation.isFinished && !operation.isCancelled {
                let error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.executionFailed.rawValue, userInfo: [type(of: self).timeoutKey: self.timeout ])
                operation.cancelWithError(error)
            }
        }
    }
    
    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) { /* No op.*/ }
    
    public func operationDidFinish(_ operation: Operation, errors: [Error]) { /* No op. */ }
}
