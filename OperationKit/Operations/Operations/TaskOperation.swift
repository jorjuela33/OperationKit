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
    fileprivate let startingOperation = BlockOperation(block: {})
    fileprivate let finishingOperation = BlockOperation(block: {})
    private let lock = NSLock()
    private var _state: State = .suspended
    
    fileprivate var aggregatedErrors = [Error]()
    
    private var canResume: Bool {
        let conditionGroup = DispatchGroup()
        
        var results = [OperationConditionResult?](repeating: nil, count: conditions.count)
        
        for (index, condition) in conditions.enumerated() {
            conditionGroup.enter()
            condition.evaluate(for: self) { result in
                results[index] = result
                conditionGroup.leave()
            }
        }
        
        conditionGroup.notify(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default)) {
            self.aggregatedErrors += results.flatMap { $0?.error }
            
            if self.isCancelled {
                let error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.conditionFailed.rawValue, userInfo: nil)
                self.aggregatedErrors.append(error)
            }
        }
        
        return aggregatedErrors.isEmpty
    }
    
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
            lock.lock()
        }
    }
    
    /// the observers for the task
    fileprivate var taskObservers: [TaskOperationObservable] = []
    
    public convenience init(operations: OperationKit.Operation...) {
        self.init(operations: operations)
    }
    
    public init(operations: [OperationKit.Operation]) {
        super.init()
        
        internalQueue.delegate = self
        internalQueue.maxConcurrentOperationCount = 1
        internalQueue.isSuspended = true
        internalQueue.addOperation(startingOperation)
        
        for operation in operations {
            let dependencies = operation.conditions.flatMap({ $0.dependency(for: operation) })
            
            for operationDependency in dependencies {
                operation.addDependency(operationDependency)
                addOperation(operationDependency)
            }
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
    
    // MARK: Instance methods methods
    
    /// cancels all the current operation in the internal queue
    override open func cancel() {
        assert(state != .cancelled)
        
        state = .cancelled
        internalQueue.cancelAllOperations()
        for observer in taskObservers {
            observer.taskOperationDidCancel(self)
        }
    }
    
    /// adds a new operation to be executed when the operation finish
    public final func complete(_ completionHandler: @escaping ([Error]?) -> Void) {
        let completeOperation = BlockOperation { [weak self] in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                completionHandler(strongSelf.aggregatedErrors)
            }
        }
        
        finishingOperation.addDependency(completeOperation)
        internalQueue.addOperation(completeOperation)
    }
    
    /// resume all the operations in the queue
    public final func resume() {
        assert(state == .suspended)
        
        state = .running
        internalQueue.isSuspended = false
        
        guard canResume else {
            cancel()
            return
        }
        
        for observer in taskObservers {
            observer.taskOperationDidResume(self)
        }
        
        guard internalQueue.operations.contains(finishingOperation) == false else { return }
        
        internalQueue.addOperation(finishingOperation)
    }
    
    /// suspends all the operations in the current queue
    public final func suspend() {
        assert(state == .running)
        
        state = .suspended
        internalQueue.isSuspended = true
        for observer in taskObservers {
            observer.taskOperationDidSuspend(self)
        }
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
            internalQueue.isSuspended = true
            state = .finished
            for observer in taskObservers {
                observer.taskOperationDidFinish(self)
            }
        }
        else if operation !== startingOperation {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}
