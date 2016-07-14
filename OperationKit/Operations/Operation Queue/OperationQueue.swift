//
//  OperationQueue.swift
//  beacon-ios
//
//  Created by Jorge Orjuela on 3/17/16.
//  Copyright © 2016 Stabilitas. All rights reserved.
//

import Foundation

protocol OperationQueueDelegate: NSObjectProtocol {
    /// Invoked when the queue is adding a new operation
    func operationQueue(operationQueue: OperationQueue, willAddOperation operation: NSOperation)
    
    /// Invoked when the operation finished
    func operationQueue(operationQueue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [NSError])
}

class OperationQueue: NSOperationQueue {
    
    weak var delegate: OperationQueueDelegate?
    
    // MARK: Instance methods
    
    /// adds the operations to the queue
    func addOperations(ops: [NSOperation]) {
        for operation in ops {
            addOperation(operation)
        }
    }
    
    // MARK: Overrided methods
    
    override func addOperation(op: NSOperation) {
        if let operation = op as? Operation {
            operation.addObserver(self)
            
            let dependencies = operation.conditions.flatMap({ $0.dependencyForOperation(operation) })
            
            for operationDependency in dependencies {
                operation.addDependency(operationDependency)
                addOperation(operationDependency)
            }
            
            operation.willEnqueue()
        } else {
            op.completionBlock = { [weak self, weak op] in
                guard let queue = self, operation = op else { return }
                
                queue.delegate?.operationQueue(queue, operationDidFinish: operation, withErrors: [])
            }
        }
        
        delegate?.operationQueue(self, willAddOperation: op)
        super.addOperation(op)
    }
}

extension OperationQueue: ObservableOperation {
    
    // MARK: ObservableOperation
    
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        addOperation(newOperation)
    }
    
    func operationDidFinish(operation: Operation, errors: [NSError]) {
        delegate?.operationQueue(self, operationDidFinish: operation, withErrors: errors)
    }
    
    func operationDidStart(operation: Operation) { /* No OP */ }
}