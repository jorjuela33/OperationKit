//
//  OperationTestObserver.swift
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

import OperationKit

struct OperationTestObserver: OperationStateObserver {
    
    let operationDidStartObserver: ((OperationKit.Operation) -> Void)?
    let operationDidProduceNewOperationObserver: ((OperationKit.Operation, Foundation.Operation) -> Void)?
    let operationDidFinishObserver: ((OperationKit.Operation, [Error]?) -> Void)?
    let operationDidResumeObserver: ((OperationKit.Operation) -> Void)?
    let operationDidSuspendObserver: ((OperationKit.Operation) -> Void)?
    
    // MARK: Initialization
    
    init(operationDidStartObserver: ((OperationKit.Operation) -> Void)? = nil,
         operationDidProduceNewOperationObserver: ((OperationKit.Operation, Foundation.Operation) -> Void)? = nil,
         operationDidFinishObserver: ((OperationKit.Operation, [Error]?) -> Void)? = nil,
         operationDidResumeObserver: ((OperationKit.Operation) -> Void)? = nil,
         operationDidSuspendObserver: ((OperationKit.Operation) -> Void)? = nil) {
        
        self.operationDidStartObserver = operationDidStartObserver
        self.operationDidProduceNewOperationObserver = operationDidProduceNewOperationObserver
        self.operationDidFinishObserver = operationDidFinishObserver
        self.operationDidResumeObserver = operationDidResumeObserver
        self.operationDidSuspendObserver = operationDidSuspendObserver
    }
    
    // MARK: OperationStateObserver
    
    func operationDidStart(_ operation: OperationKit.Operation) {
        operationDidStartObserver?(operation)
    }
    
    func operation(_ operation: OperationKit.Operation, didProduceOperation newOperation: Foundation.Operation) {
        operationDidProduceNewOperationObserver?(operation, newOperation)
    }
    
    func operationDidFinish(_ operation: OperationKit.Operation, errors: [Error]) {
        operationDidFinishObserver?(operation, errors)
    }
    
    func operationDidResume(_ operation: Operation) {
        self.operationDidResumeObserver?(operation)
    }
    
    func operationDidSuspend(_ operation: Operation) {
        self.operationDidSuspendObserver?(operation)
    }
}
