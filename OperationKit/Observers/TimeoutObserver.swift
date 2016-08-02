//
//  TimeoutObserver.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 8/2/16.
//  Copyright © 2016 Chessclub. All rights reserved.
//

import Foundation

struct TimeoutObserver: ObservableOperation {
    
    static let timeoutKey = "Timeout"
    
    private let timeout: NSTimeInterval
    
    // MARK: Initialization
    
    init(timeout: NSTimeInterval = 30) {
        self.timeout = timeout
    }
    
    // MARK: OperationObserver
    
    func operationDidStart(operation: Operation) {
        // When the operation starts, queue up a block to cause it to time out.
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC)))
        
        dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            if !operation.finished && !operation.cancelled {
                let error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.ExecutionFailed.rawValue, userInfo: [self.dynamicType.timeoutKey: self.timeout ])
                operation.cancelWithError(error)
            }
        }
    }
    
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) { /* No op.*/ }
    
    func operationDidFinish(operation: Operation, errors: [NSError]) { /* No op. */ }
}
