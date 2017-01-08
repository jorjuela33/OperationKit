//
//  OperationTestObserver.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/8/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import OperationKit

struct OperationTestObserver: OperationStateObserver {
    
    let operationDidStartObserver: ((OperationKit.Operation) -> Void)?
    let operationDidProduceNewOperationObserver: ((OperationKit.Operation, Foundation.Operation) -> Void)?
    let operationDidFinishObserver: ((OperationKit.Operation, [Error]?) -> Void)?
    let operationDidResumeObserver: ((OperationKit.Operation) -> Void)?
    let operationDidSuspendObserver: ((OperationKit.Operation) -> Void)?
    
    // MARK: Initialization
    
    init(operationDidStartObserver: ((OperationKit.Operation) -> Void)? = nil,
         operationDidProduceNewOperationObserver: ((OperationKit.Operation, Foundation.Operation) -> Void)? = nil,
         operationDidFinishObserver: ((OperationKit.Operation, [Error]?) -> Void)? = nil,
         operationDidResumeObserver: ((OperationKit.Operation) -> Void)? = nil,
         operationDidSuspendObserver: ((OperationKit.Operation) -> Void)? = nil) {
        
        self.operationDidStartObserver = operationDidStartObserver
        self.operationDidProduceNewOperationObserver = operationDidProduceNewOperationObserver
        self.operationDidFinishObserver = operationDidFinishObserver
        self.operationDidResumeObserver = operationDidResumeObserver
        self.operationDidSuspendObserver = operationDidSuspendObserver
    }
    
    // MARK: OperationStateObserver
    
    func operationDidStart(_ operation: OperationKit.Operation) {
        operationDidStartObserver?(operation)
    }
    
    func operation(_ operation: OperationKit.Operation, didProduceOperation newOperation: Foundation.Operation) {
        operationDidProduceNewOperationObserver?(operation, newOperation)
    }
    
    func operationDidFinish(_ operation: OperationKit.Operation, errors: [Error]) {
        operationDidFinishObserver?(operation, errors)
    }
    
    func operationDidResume(_ operation: Operation) {
        self.operationDidResumeObserver?(operation)
    }
    
    func operationDidSuspend(_ operation: Operation) {
        self.operationDidSuspendObserver?(operation)
    }
}
