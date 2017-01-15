//
//  BlockObserver.swift
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

struct BlockObserver: ObservableOperation {
    
    private let startHandler: ((Operation) -> Void)?
    private let produceHandler: ((Operation, Foundation.Operation) -> Void)?
    private let finishHandler: ((Operation, [Error]) -> Void)?
    
    init(
        startHandler: ((Operation) -> Void)? = nil,
        produceHandler: ((Operation, Foundation.NSOperation) -> Void)? = nil,
        finishHandler: ((Operation, [Error]) -> Void)? = nil) {
        
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: ObservableOperation
    
    public func operationDidStart(_ operation: Operation) {
        startHandler?(operation)
    }
    
    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) {
        produceHandler?(operation, newOperation)
    }
    
    public func operationDidFinish(_ operation: Operation, errors: [Error]) {
        finishHandler?(operation, errors)
    }
}
