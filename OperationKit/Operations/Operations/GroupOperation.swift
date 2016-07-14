//
//  GroupOperation.swift
//  beacon-ios
//
//  Created by Jorge Orjuela on 3/17/16.
//  Copyright © 2016 Stabilitas. All rights reserved.
//

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