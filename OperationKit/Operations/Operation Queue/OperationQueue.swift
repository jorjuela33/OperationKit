//
//  OperationQueue.swift
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

public protocol OperationQueueDelegate: NSObjectProtocol {
    /// Invoked when the queue is adding a new operation
    func operationQueue(operationQueue: OperationQueue, willAddOperation operation: NSOperation)
    
    /// Invoked when the operation finished
    func operationQueue(operationQueue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [NSError])
}

public class OperationQueue: NSOperationQueue {
    
    weak var delegate: OperationQueueDelegate?
    
    // MARK: Instance methods
    
    /// adds the operations to the queue
    func addOperations(ops: [NSOperation]) {
        for operation in ops {
            addOperation(operation)
        }
    }
    
    // MARK: Overrided methods
    
    override public func addOperation(op: NSOperation) {
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
    
    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        addOperation(newOperation)
    }
    
    public func operationDidFinish(operation: Operation, errors: [NSError]) {
        delegate?.operationQueue(self, operationDidFinish: operation, withErrors: errors)
    }
    
    public func operationDidStart(operation: Operation) { /* No OP */ }
}