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

public protocol TaskOperationObservable: class {
    func taskOperationDidCancel(_ taskOperation: TaskOperation)
    func taskOperationDidFinish(_ taskOperation: TaskOperation)
    func taskOperationDidResume(_ taskOperation: TaskOperation)
    func taskOperationDidSuspend(_ taskOperation: TaskOperation)
}

open class TaskOperation: OperationKit.Operation {
    
    fileprivate let internalQueue = OperationKit.OperationQueue()
    fileprivate var completeOperations: [BlockOperation] = []
    fileprivate let startingOperation = BlockOperation(block: {})
    fileprivate let finishingOperation = BlockOperation(block: {})
    private let lock = NSLock()
    private var _state: State = .suspended
    
    fileprivate var aggregatedErrors = [Error]()
    
    /// the allowed states for the Task
    public enum State {
        case cancelled
        case finished
        case running
        case suspended
    }
    
    /// the identifier for the operation task
    public var identifier = arc4random()
    
    /// the current state for the task
    public var state: State {
        get {
            lock.lock()
            defer { lock.unlock() }
            
            return _state
        }
        
        set {
            lock.lock()
            _state = newValue
            lock.unlock()
        }
    }
    
    /// the observers for the task
    fileprivate var taskObservers: [TaskOperationObservable] = []
    
    // MARK: Initialization
    
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
    
    /// adds a new observer to the operation task
    public final func add(observer: TaskOperationObservable) {
        taskObservers.append(observer)
    }
    
    /// Adds the operation to the internal queue
    open func addOperation(_ operation: Foundation.Operation) {
        for completeOperation in completeOperations {
            completeOperation.addDependency(operation)
        }
        
        internalQueue.addOperation(operation)
    }
    
    /// Adds multiple operations to the queue
    open func addOperations(_ operations: [Foundation.Operation]) {
        for operation in operations {
            addOperation(operation)
        }
    }
    
    /// Adds the new error to the internal errors array
    public final func aggregateError(_ error: NSError) {
        aggregatedErrors.append(error)
    }
    
    /// For use by subclassers.
    open func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [Error]) { }
    
    // MARK: Instance methods methods
    
    /// cancels all the current operation in the internal queue
    override open func cancel()  {
        assert(state != .cancelled)
        
        state = .cancelled
        internalQueue.cancelAllOperations()
        for observer in taskObservers {
            observer.taskOperationDidCancel(self)
        }
    }
    
    /// adds a new operation to be executed when the operation finish
    @discardableResult
    public final func complete(_ completionHandler: @escaping ([Error]?) -> Void) -> TaskOperation {
        let completeOperation = BlockOperation { [weak self] in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                completionHandler(strongSelf.aggregatedErrors)
            }
        }
        
        for operation in internalQueue.operations {
            guard operation !== finishingOperation && operation !== startingOperation else { continue }
            
            completeOperation.addDependency(operation)
        }
        
        completeOperations.append(completeOperation)
        finishingOperation.addDependency(completeOperation)
        internalQueue.addOperation(completeOperation)
        return self
    }
    
    /// resume all the operations in the queue
    @discardableResult
    public final func resume() -> TaskOperation {
        assert(state == .suspended)
        
        state = .running
        internalQueue.isSuspended = false
        for observer in taskObservers {
            observer.taskOperationDidResume(self)
        }
        
        return self
    }
    
    /// suspends all the operations in the current queue
    @discardableResult
    public final func suspend() -> TaskOperation {
        assert(state == .running)
        
        state = .suspended
        internalQueue.isSuspended = true
        for observer in taskObservers {
            observer.taskOperationDidSuspend(self)
        }
        
        return self
    }
    
    // MARK: Overrided methods
    
    override open func finished(_ errors: [Error]) {
        completeOperations.removeAll()
        internalQueue.isSuspended = true
        state = .finished
        for observer in taskObservers {
            observer.taskOperationDidFinish(self)
        }
    }
    
    override open func execute() {
        resume()
        internalQueue.addOperation(finishingOperation)
    }
}

extension TaskOperation: OperationQueueDelegate {
    
    // MARK: OperationQueueDelegate
    
    final public func operationQueue(_ operationQueue: OperationKit.OperationQueue, willAddOperation operation: Foundation.Operation) {
        assert(!finishingOperation.isFinished && !finishingOperation.isExecuting, "cannot add new operations to a group after the group has completed")
        
        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }
        
        if operation !== startingOperation {
            operation.addDependency(startingOperation)
        }
    }
    
    public func operationQueue(_ operationQueue: OperationKit.OperationQueue, operationDidFinish operation: Foundation.Operation, withErrors errors: [Error]) {
        aggregatedErrors.append(contentsOf: errors)
        
        if operation === finishingOperation {
            finish(aggregatedErrors)
        }
        else if operation !== startingOperation {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}
