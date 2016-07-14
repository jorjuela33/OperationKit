//
//  OperationCondition.swift
//  beacon-ios
//
//  Created by Jorge Orjuela on 3/18/16.
//  Copyright © 2016 Chessclub. All rights reserved.
//

import Foundation

let OperationConditionKey = "_operationConditionKey"

enum OperationErrorCode: Int {
    case ConditionFailed = 1
    case ExecutionFailed = 2
}

protocol OperationCondition {
    
    /// The name of the condition. This is used in userInfo dictionaries of `.ConditionFailed`
    static var name: String { get }
    
    /// Returns the operation dependency for the given operation
    func dependencyForOperation(operation: Operation) -> NSOperation?
    
    /// Evaluate the condition, to see if it has been satisfied or not.
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void)
}

enum OperationConditionResult {
    case Satisfied
    case Failed(NSError)
    
    var error: NSError? {
        switch self {
        case .Failed(let error):
            return error
            
        default:
            return nil
        }
    }
}