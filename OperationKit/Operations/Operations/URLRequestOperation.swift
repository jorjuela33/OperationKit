//
//  URLRequestOperation.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/6/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import Foundation

open class URLRequestOperation: Operation {
   
    public typealias ValidationBlock = (URLRequest?, HTTPURLResponse, Data?) -> Error?
    
    private let acceptableStatusCodes = Array(200..<300)
    fileprivate var validations: [() -> Error?] = []
    
    internal var session: URLSession!
    internal var sessionTask: URLSessionTask!
    
    /// the data returned for the server
    open fileprivate(set) var data = Data()
    
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
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        sessionTask = session.dataTask(with: request)
        addCondition(ReachabilityCondition(host: request.url!))
    }
    
    // MARK: Instance methods
    
    /// Resume the task.
    @discardableResult
    public func resume() -> Self {
        assert(isExecuting == true)
        
        sessionTask?.resume()
        return self
    }
    
    /// Suspend the task.
    ///
    /// Suspending a task preventing from continuing to
    /// load data.
    @discardableResult
    public func suspend() -> Self {
        assert(isExecuting == true)
        
        sessionTask?.suspend()
        return self
    }
    
    /// Validates the request, using the specified closure.
    ///
    /// validationBlock - A closure to validate the request.
    @discardableResult
    open func validate(_ validationBlock: @escaping ValidationBlock) -> Self {
        let _validationBlock: (() -> Error?) = { [unowned self] in
            guard let response = self.response else { return nil }
            
            return validationBlock(self.sessionTask?.originalRequest, response, self.data)
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
        return validate {[unowned self] _, response, _ in
            return self.validate(acceptableStatusCodes: acceptableStatusCodes, response: response)
        }
    }
    
    // MARK: Overrided methods
    
    override open func execute() {
        sessionTask?.resume()
    }
    
    override open func finished(_ errors: [Error]) {
        session.invalidateAndCancel()
    }
    
    // MARK: Private methods
    
    private final func validate<S: Sequence>(acceptableStatusCodes: S, response: HTTPURLResponse) -> Error? where S.Iterator.Element == Int {
        var error: NSError?
        if !acceptableStatusCodes.contains(response.statusCode) {
            let userInfo = [NSLocalizedDescriptionKey: "unacceptable status code \(response.statusCode)"]
            error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.conditionFailed.rawValue, userInfo: userInfo)
        }
        
        return error
    }
}

extension URLRequestOperation: URLSessionDataDelegate {
    
    // MARK: NSURLSessionDataDelegate
    
    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        guard isCancelled == false else {
            finish()
            sessionTask?.cancel()
            return
        }
        
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.data.append(data)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard isCancelled == false else { return }
        
        var errors: [Error] = []
        if let error = error {
            errors.append(error)
        }
        
        for validation in validations {
            guard let error = validation() else { continue }
            
            errors.append(error)
        }
        
        finish(errors)
    }
}
