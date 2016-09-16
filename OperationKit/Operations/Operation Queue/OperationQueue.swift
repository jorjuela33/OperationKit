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
    func operationQueue(_ operationQueue: OperationQueue, willAddOperation operation: Foundation.Operation)
    
    /// Invoked when the operation finished
    func operationQueue(_ operationQueue: OperationQueue, operationDidFinish operation: Foundation.Operation, withErrors errors: [Error])
}

open class OperationQueue: Foundation.OperationQueue {
    
    weak var delegate: OperationQueueDelegate?
    
    // MARK: Instance methods
    
    /// adds the operations to the queue
    open func addOperations(_ ops: [Foundation.Operation]) {
        for operation in ops {
            addOperation(operation)
        }
    }
    
    // MARK: Overrided methods
    
    override open func addOperation(_ op: Foundation.Operation) {
        if let operation = op as? Operation {
            operation.addObserver(self)
            
            let dependencies = operation.conditions.flatMap({ $0.dependency(for: operation) })
            
            for operationDependency in dependencies {
                operation.addDependency(operationDependency)
                addOperation(operationDependency)
            }
            
            operation.willEnqueue()
        } else {
            op.completionBlock = { [weak self, weak op] in
                guard let queue = self, let operation = op else { return }
                
                queue.delegate?.operationQueue(queue, operationDidFinish: operation, withErrors: [])
            }
        }
        
        delegate?.operationQueue(self, willAddOperation: op)
        super.addOperation(op)
    }
}

extension OperationQueue: ObservableOperation {
    
    // MARK: ObservableOperation
    
    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) {
        addOperation(newOperation)
    }
    
    public func operationDidFinish(_ operation: Operation, errors: [Error]) {
        delegate?.operationQueue(self, operationDidFinish: operation, withErrors: errors)
    }
    
    public func operationDidStart(_ operation: Operation) { /* No OP */ }
}
