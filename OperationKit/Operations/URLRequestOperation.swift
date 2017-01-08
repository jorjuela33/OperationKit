//
//  URLRequestOperation.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/6/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import Foundation

open class URLRequestOperation: Operation {
   
    public typealias ValidationBlock = (URLRequest?, HTTPURLResponse) -> Error?
    
    /// the allowed states for the Request
    public enum State {
        case initialized
        case finished
        case running
        case suspended
    }
    
    private let acceptableStatusCodes = Array(200..<300)
    fileprivate var aggregatedErrors: [Error] = []
    fileprivate var finishingOperation: BlockOperation!
    fileprivate let operationQueue = Foundation.OperationQueue()
    fileprivate let lock = NSLock()
    fileprivate var _state: State = .initialized
    fileprivate var validations: [() -> Error?] = []
    
    internal var session: URLSession!
    internal var sessionTask: URLSessionTask!
    
    /// the state for the current request
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
    
    /// the response from the host
    open var response: HTTPURLResponse? {
        return sessionTask.response as? HTTPURLResponse
    }
    
    /// the URL for this operation
    open var url: URL? {
        return sessionTask.originalRequest?.url
    }
    
    // MARK: Initialization
    
    public init(request: URLRequest, sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default) {
        super.init()
        
        name = request.url?.absoluteString
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.isSuspended = true
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        sessionTask = session.dataTask(with: request)
        addCondition(ReachabilityCondition(host: request.url!))
        finishingOperation = BlockOperation(block: { [unowned self] in
            self.finish(self.aggregatedErrors)
        })
        operationQueue.addOperation(finishingOperation)
    }
    
    // MARK: Instance methods
    
    /// adds a new operation to be executed when 
    /// the current operation is finishing
    func addSubOperation(_ blockOperation: BlockOperation) {
        assert(isFinished == false && isCancelled == false)
        
        finishingOperation.addDependency(blockOperation)
        operationQueue.addOperation(blockOperation)
    }
    
    /// agregate a new error in the array of errors
    func aggregate(_ error: Error) {
        aggregatedErrors.append(error)
    }
    
    /// Resume the operation.
    @discardableResult
    public func resume() -> Self {
        assert(state == .suspended)
        
        state = .running
        if sessionTask.state == .completed {
            operationQueue.isSuspended = false
        }
        else {
            sessionTask.resume()
        }
        
        for observer in observers {
            guard let ob = observer as? OperationStateObserver else { continue }
            
            ob.operationDidResume(self)
        }
        
        return self
    }
    
    /// Suspend the operation.
    ///
    /// Suspending a task preventing from continuing to
    /// load data.
    @discardableResult
    public func suspend() -> Self {
        assert(state != .finished)
        
        state = .suspended
        operationQueue.isSuspended = true
        if sessionTask.state == .running {
            sessionTask.suspend()
        }
        
        for observer in observers {
            guard let ob = observer as? OperationStateObserver else { continue }
            
            ob.operationDidSuspend(self)
        }
        
        return self
    }
    
    /// Validates the request, using the specified closure.
    ///
    /// validationBlock - A closure to validate the request.
    @discardableResult
    open func validate(_ validationBlock: @escaping ValidationBlock) -> Self {
        let _validationBlock: (() -> Error?) = { [unowned self] in
            guard let response = self.response else { return nil }
            
            return validationBlock(self.sessionTask?.originalRequest, response)
        }
        
        validations.append(_validationBlock)
        return self
    }
    
    /// Validates that the response has a status code in the specified sequence.
    ///
    /// acceptableStatusCodes - The range of acceptable status codes.
    @discardableResult
    open func validate() -> Self {
        return validate(acceptableStatusCodes: acceptableStatusCodes)
    }
    
    /// Validates that the response has a status code in the specified sequence.
    ///
    /// acceptableStatusCodes - The range of acceptable status codes.
    @discardableResult
    open func validate<S: Sequence>(acceptableStatusCodes: S) -> Self where S.Iterator.Element == Int {
        return validate {[unowned self] _, response in
            return self.validate(acceptableStatusCodes: acceptableStatusCodes, response: response)
        }
    }
    
    // MARK: Overrided methods
    
    override open func execute() {
        guard state == .initialized else { return }
            
        state = .running
        sessionTask?.resume()
    }
    
    override open func finished(_ errors: [Error]) {
        state = .finished
        operationQueue.cancelAllOperations()
        session.invalidateAndCancel()
    }
    
    // MARK: Private methods
    
    fileprivate final func executeValidations() {
        for validation in validations {
            guard let error = validation() else { continue }
            
            aggregatedErrors.append(error)
        }
    }
    
    private final func validate<S: Sequence>(acceptableStatusCodes: S, response: HTTPURLResponse) -> Error? where S.Iterator.Element == Int {
        var error: Error?
        if !acceptableStatusCodes.contains(response.statusCode) {
            error = OperationKitError.unacceptableStatusCode(code: response.statusCode)
        }
        
        return error
    }
}

extension URLRequestOperation: URLSessionTaskDelegate {
    
    // MARK: URLSessionTaskDelegate
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard isCancelled == false else { return }
        
        if let error = error {
            aggregatedErrors.append(error)
        }
        
        for validation in validations {
            guard let error = validation() else { continue }
            
            aggregatedErrors.append(error)
        }
        
        executeValidations()
        if state == .running {
            operationQueue.isSuspended = false
        }
    }
}
