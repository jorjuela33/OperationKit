//
//  Operation.swift
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

import CoreData
import UIKit

public let OperationErrorDomainCode = "com.operation.domain.error"

public protocol ObservableOperation {
    /// Invoked immediately prior to the `Operation`'s `execute()` method.
    func operationDidStart(_ operation: Operation)
    
    /// Invoked when `Operation.produceOperation(_:)` is executed.
    func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation)
    
    /// Invoked as an `Operation` finishes, along with any errors produced during
    /// execution (or readiness evaluation).
    func operationDidFinish(_ operation: Operation, errors: [Error])
}

open class Operation: Foundation.Operation {
    
    fileprivate enum State: Int, Comparable {
        /// The initial state of an `Operation`.
        case initialized
        
        /// The `Operation` is ready to begin evaluating conditions.
        case pending
        
        /// The `Operation` is evaluating conditions.
        case evaluatingConditions
        
        /// The `Operation`'s conditions have all been satisfied, 
        /// and it is ready to execute.
        case ready
        
        /// The `Operation` is executing.
        case executing
        
        /// Execution of the `Operation` has finished, but it has not yet notified
        /// the queue of this.
        case finishing
        
        /// The `Operation` has finished executing.
        case finished
        
        func canTransitionToState(_ target: State) -> Bool {
            switch (self, target) {
            case (.initialized, .pending):
                return true
            case (.pending, .evaluatingConditions):
                return true
            case (.evaluatingConditions, .ready):
                return true
            case (.ready, .executing):
                return true
            case (.ready, .finishing):
                return true
            case (.executing, .finishing):
                return true
            case (.finishing, .finished):
                return true
            case (.pending, .finishing):
                return true
            default:
                return false
            }
        }
    }
    
    private var hasFinishedAlready = false
    private var internalErrors: [Error] = []
    private var lock = NSLock()
    private var _state: State = .initialized
    
    fileprivate var state: State {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _state
        }
        
        set(newState) {
            assert(_state.canTransitionToState(newState))
            
            guard _state != .finished else { return }
            
            willChangeValue(forKey: "state")
            lock.lock()
            _state = newState
            lock.unlock()
            didChangeValue(forKey: "state")
        }
    }
    
    /// The conditions for this operation
    fileprivate(set) var conditions: [OperationCondition] = []
    
    /// The observers of the operation
    fileprivate(set) var observers = [ObservableOperation]()
    
    override open var isAsynchronous: Bool {
        return true
    }
    
    /// Wheter the resquest is user initiated or not
    open var userInitiated: Bool {
        get {
            return qualityOfService == .userInitiated
        }
        
        set {
            assert(state < .executing)
            
            qualityOfService = newValue ? .userInitiated : .default
        }
    }
    
    override open var isExecuting: Bool {
        return state == .executing
    }
    
    override open var isFinished: Bool {
        return state == .finished
    }
    
    override open var isReady: Bool {
        switch state {
        case .initialized:
            return isCancelled
            
        case .pending:
            guard !isCancelled else {
                return true
            }
            
            if super.isReady {
                evaluateConditions()
            }
            
            return false
        case .ready:
            return super.isReady || isCancelled
            
        default:
            return false
        }
    }
    
    // MARK: Intance methods
    
    /// Adds a new condition for this operation
    public final func addCondition(_ operationCondition: OperationCondition) {
        assert(state < .evaluatingConditions)
        
        conditions.append(operationCondition)
    }
    
    /// Adds a new observer for the operation
    open func addObserver(_ observer: ObservableOperation) {
        assert(state < .executing)
        
        observers.append(observer)
    }
    
    /// Cancels the current request
    ///
    /// error - The error produced by the request
    public final func cancelWithError(_ error: Error) {
        internalErrors.append(error)
        cancel()
    }
    
    /// The entry point of all operations
    open func execute() {
        finish()
    }
    
    /// Finish the current request 
    ///
    /// errors - Optional value containing the errors
    ///          produced by the operation
    public final func finish(_ errors: [Error] = []) {
        guard hasFinishedAlready == false else { return }
        
        let combinedErrors = internalErrors + errors
        hasFinishedAlready = true
        state = .finishing
        finished(combinedErrors)
        
        for observer in observers {
            observer.operationDidFinish(self, errors: combinedErrors)
        }
        
        observers.removeAll()
        state = .finished
    }
    
    /// Should be overriden for the child operations
    open func finished(_ errors: [Error]) {
        // No op.
    }
    
    /// Finish the current request
    ///
    /// error - The error produced by the request
    public final func finishWithError(_ error: Error?) {
        guard let error = error else {
            finish()
            return
        }
        
        finish([error])
    }
    
    /// Notify to the observer when a suboperation is created for this operation
    public final func produceOperation(_ operation: Foundation.Operation) {
        for observer in observers {
            observer.operation(self, didProduceOperation: operation)
        }
    }
    
    /// Indicates that the Operation can now begin to evaluate readiness conditions,
    /// if appropriate.
    open func willEnqueue() {
        state = .pending
    }
    
    // MARK: KVO methods
    
    class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["state" as NSObject]
    }
    
    // MARK: Overrided methods
    
    override final public func main() {
        assert(state == .ready)
        
        guard isCancelled == false && internalErrors.isEmpty else {
            finish()
            return
        }
        
        state = .executing
        
        for observer in observers {
            observer.operationDidStart(self)
        }
        
        execute()
    }
    
    override open func start() {
        super.start()
        if isCancelled {
            finish()
        }
    }
    
    // MARK: Private methods
    
    fileprivate func evaluateConditions() {
        assert(state == .pending && !isCancelled)
        
        state = .evaluatingConditions
        
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
            self.internalErrors += results.flatMap { $0?.error }
            
            if self.isCancelled {
                let error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.conditionFailed.rawValue, userInfo: nil)
                self.internalErrors.append(error)
            }
            
            self.state = .ready
        }
    }
}

private func <(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

private func ==(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
