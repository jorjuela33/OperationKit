//
//  TimeoutObserver.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 8/2/16.
//  Copyright © 2016 Chessclub. All rights reserved.
//

import Foundation

public struct TimeoutObserver: ObservableOperation {
    
    public static let timeoutKey = "Timeout"
    
    private let timeout: TimeInterval
    
    // MARK: Initialization
    
    public init(timeout: TimeInterval = 30) {
        self.timeout = timeout
    }
    
    // MARK: OperationObserver
    
    public func operationDidStart(_ operation: Operation) {
        // When the operation starts, queue up a block to cause it to time out.
        let when = DispatchTime.now() + Double(Int64(timeout * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).asyncAfter(deadline: when) {
            if !operation.isFinished && !operation.isCancelled {
                let error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.executionFailed.rawValue, userInfo: [type(of: self).timeoutKey: self.timeout ])
                operation.cancelWithError(error)
            }
        }
    }
    
    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) { /* No op.*/ }
    
    public func operationDidFinish(_ operation: Operation, errors: [Error]) { /* No op. */ }
}
