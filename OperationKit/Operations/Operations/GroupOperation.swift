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

class GroupOperation: Operation {
    
    private let internalQueue = OperationQueue()
    private let startingOperation = NSBlockOperation(block: {})
    private let finishingOperation = NSBlockOperation(block: {})
    
    private var aggregatedErrors = [NSError]()
    
    convenience init(operations: NSOperation...) {
        self.init(operations: operations)
    }
    
    init(operations: [NSOperation]) {
        super.init()
        
        internalQueue.delegate = self
        internalQueue.suspended = true
        internalQueue.addOperation(startingOperation)
        
        for operation in operations {
            internalQueue.addOperation(operation)
        }
    }
    
    // MARK: Instance methods
    
    /// Adds the operation to the internal queue
    func addOperation(operation: NSOperation) {
        internalQueue.addOperation(operation)
    }
    
    /// Adds multiple operations to the queue
    func addOperations(operations: [NSOperation]) {
        internalQueue.addOperations(operations)
    }
    
    /// Adds the new error to the internal errors array
    final func aggregateError(error: NSError) {
        aggregatedErrors.append(error)
    }
    
    /// For use by subclassers.
    func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) { }
    
    // MARK: Overrided methods
    
    override func cancel() {
        internalQueue.cancelAllOperations()
        super.cancel()
    }
    
    override func execute() {
        internalQueue.suspended = false
        internalQueue.addOperation(finishingOperation)
    }
}

extension GroupOperation: OperationQueueDelegate {
    
    // MARK: OperationQueueDelegate
    
    final func operationQueue(operationQueue: OperationQueue, willAddOperation operation: NSOperation) {
        assert(!finishingOperation.finished && !finishingOperation.executing, "cannot add new operations to a group after the group has completed")
        
        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }
        
        if operation !== startingOperation {
            operation.addDependency(startingOperation)
        }
    }
    
    func operationQueue(operationQueue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [NSError]) {
        aggregatedErrors.appendContentsOf(errors)
        
        if operation === finishingOperation {
            internalQueue.suspended = true
            finish(aggregatedErrors)
        }
        else if operation !== startingOperation {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}