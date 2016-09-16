//
//  GroupOperation.swift
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

open class GroupOperation: Operation {
    
    fileprivate let internalQueue = OperationQueue()
    fileprivate let startingOperation = BlockOperation(block: {})
    fileprivate let finishingOperation = BlockOperation(block: {})
    
    fileprivate var aggregatedErrors = [Error]()
    
    public convenience init(operations: Foundation.Operation...) {
        self.init(operations: operations)
    }
    
    public init(operations: [Foundation.Operation]) {
        super.init()
        
        internalQueue.delegate = self
        internalQueue.isSuspended = true
        internalQueue.addOperation(startingOperation)
        
        for operation in operations {
            internalQueue.addOperation(operation)
        }
    }
    
    // MARK: Instance methods
    
    /// Adds the operation to the internal queue
    open func addOperation(_ operation: Foundation.Operation) {
        internalQueue.addOperation(operation)
    }
    
    /// Adds multiple operations to the queue
    open func addOperations(_ operations: [Foundation.Operation]) {
        internalQueue.addOperations(operations)
    }
    
    /// Adds the new error to the internal errors array
    public final func aggregateError(_ error: NSError) {
        aggregatedErrors.append(error)
    }
    
    /// For use by subclassers.
    open func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [Error]) { }
    
    // MARK: Overrided methods
    
    override open func cancel() {
        internalQueue.cancelAllOperations()
        super.cancel()
    }
    
    override open func execute() {
        internalQueue.isSuspended = false
        internalQueue.addOperation(finishingOperation)
    }
}

extension GroupOperation: OperationQueueDelegate {
    
    // MARK: OperationQueueDelegate
    
    final public func operationQueue(_ operationQueue: OperationQueue, willAddOperation operation: Foundation.Operation) {
        assert(!finishingOperation.isFinished && !finishingOperation.isExecuting, "cannot add new operations to a group after the group has completed")
        
        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }
        
        if operation !== startingOperation {
            operation.addDependency(startingOperation)
        }
    }
    
    public func operationQueue(_ operationQueue: OperationQueue, operationDidFinish operation: Foundation.Operation, withErrors errors: [Error]) {
        
        aggregatedErrors.append(contentsOf: errors)
        
        if operation === finishingOperation {
            internalQueue.isSuspended = true
            finish(aggregatedErrors)
        }
        else if operation !== startingOperation {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}
