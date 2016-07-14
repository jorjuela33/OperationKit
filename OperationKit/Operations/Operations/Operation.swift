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

let OperationErrorDomainCode = "com.operation.domain.error"

protocol ObservableOperation {
    /// Invoked immediately prior to the `Operation`'s `execute()` method.
    func operationDidStart(operation: Operation)
    
    /// Invoked when `Operation.produceOperation(_:)` is executed.
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation)
    
    /// Invoked as an `Operation` finishes, along with any errors produced during
    /// execution (or readiness evaluation).
    func operationDidFinish(operation: Operation, errors: [NSError])
}

class Operation: NSOperation {
    // MARK: Properties
    
    private enum State: Int, Comparable {
        /// The initial state of an `Operation`.
        case Initialized
        
        /// The `Operation` is ready to begin evaluating conditions.
        case Pending
        
        /// The `Operation` is evaluating conditions.
        case EvaluatingConditions
        
        /// The `Operation`'s conditions have all been satisfied, 
        /// and it is ready to execute.
        case Ready
        
        /// The `Operation` is executing.
        case Executing
        
        /// Execution of the `Operation` has finished, but it has not yet notified
        /// the queue of this.
        case Finishing
        
        /// The `Operation` has finished executing.
        case Finished
        
        func canTransitionToState(target: State) -> Bool {
            switch (self, target) {
            case (.Initialized, .Pending):
                return true
            case (.Pending, .EvaluatingConditions):
                return true
            case (.EvaluatingConditions, .Ready):
                return true
            case (.Ready, .Executing):
                return true
            case (.Ready, .Finishing):
                return true
            case (.Executing, .Finishing):
                return true
            case (.Finishing, .Finished):
                return true
            case (.Pending, .Finishing):
                return true
            default:
                return false
            }
        }
    }
    
    private var hasFinishedAlready = false
    private var internalErrors: [NSError] = []
    private var lock = NSLock()
    private var _state: State = .Initialized
    
    private var state: State {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _state
        }
        
        set(newState) {
            assert(_state.canTransitionToState(newState))
            
            guard _state != .Finished else { return }
            
            willChangeValueForKey("state")
            lock.lock()
            _state = newState
            lock.unlock()
            didChangeValueForKey("state")
        }
    }
    
    /// The conditions for this operation
    private(set) var conditions: [OperationCondition] = []
    
    /// The observers of the operation
    private(set) var observers = [ObservableOperation]()
    
    override var asynchronous: Bool {
        return true
    }
    
    /// Wheter the resquest is user initiated or not
    var userInitiated: Bool {
        get {
            return qualityOfService == .UserInitiated
        }
        
        set {
            assert(state < .Executing)
            
            qualityOfService = newValue ? .UserInitiated : .Default
        }
    }
    
    override var executing: Bool {
        return state == .Executing
    }
    
    override var finished: Bool {
        return state == .Finished
    }
    
    override var ready: Bool {
        switch state {
        case .Initialized:
            return cancelled
            
        case .Pending:
            guard !cancelled else {
                return true
            }
            
            if super.ready {
                evaluateConditions()
            }
            
            return false
        case .Ready:
            return super.ready || cancelled
            
        default:
            return false
        }
    }
    
    // MARK: Intance methods
    
    /// Adds a new condition for this operation
    final func addCondition(operationCondition: OperationCondition) {
        assert(state < .EvaluatingConditions)
        
        conditions.append(operationCondition)
    }
    
    /// Adds a new observer for the operation
    func addObserver(observer: ObservableOperation) {
        assert(state < .Executing)
        
        observers.append(observer)
    }
    
    /// Cancels the current request
    ///
    /// error - The error produced by the request
    final func cancelWithError(error: NSError) {
        internalErrors.append(error)
        cancel()
    }
    
    /// The entry point of all operations
    func execute() {
        finish()
    }
    
    /// Finish the current request 
    ///
    /// errors - Optional value containing the errors
    ///          produced by the operation
    final func finish(errors: [NSError] = []) {
        guard hasFinishedAlready == false else { return }
        
        let combinedErrors = internalErrors + errors
        hasFinishedAlready = true
        state = .Finishing
        finished(combinedErrors)
        
        for observer in observers {
            observer.operationDidFinish(self, errors: combinedErrors)
        }
        
        observers.removeAll()
        state = .Finished
    }
    
    /// Should be overriden for the child operations
    func finished(errors: [NSError]) {
        // No op.
    }
    
    /// Finish the current request
    ///
    /// error - The error produced by the request
    final func finishWithError(error: NSError?) {
        guard let error = error else {
            finish()
            return
        }
        
        finish([error])
    }
    
    /// Notify to the observer when a suboperation is created for this operation
    final func produceOperation(operation: NSOperation) {
        for observer in observers {
            observer.operation(self, didProduceOperation: operation)
        }
    }
    
    /// Indicates that the Operation can now begin to evaluate readiness conditions,
    /// if appropriate.
    func willEnqueue() {
        state = .Pending
    }
    
    // MARK: KVO methods
    
    class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return ["state"]
    }
    
    class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return ["state"]
    }
    
    class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["state"]
    }
    
    // MARK: Overrided methods
    
    override final func main() {
        assert(state == .Ready)
        
        guard cancelled == false && internalErrors.isEmpty else {
            finish()
            return
        }
        
        state = .Executing
        
        for observer in observers {
            observer.operationDidStart(self)
        }
        
        execute()
    }
    
    override func start() {
        super.start()
        if cancelled {
            finish()
        }
    }
    
    // MARK: Private methods
    
    private func evaluateConditions() {
        assert(state == .Pending && !cancelled)
        
        state = .EvaluatingConditions
        
        let conditionGroup = dispatch_group_create()
        
        var results = [OperationConditionResult?](count: conditions.count, repeatedValue: nil)
        
        for (index, condition) in conditions.enumerate() {
            dispatch_group_enter(conditionGroup)
            condition.evaluateForOperation(self) { result in
                results[index] = result
                dispatch_group_leave(conditionGroup)
            }
        }
        
        dispatch_group_notify(conditionGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            self.internalErrors += results.flatMap { $0?.error }
            
            if self.cancelled {
                let error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.ConditionFailed.rawValue, userInfo: nil)
                self.internalErrors.append(error)
            }
            
            self.state = .Ready
        }
    }
}

private func <(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

private func ==(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue == rhs.rawValue
}