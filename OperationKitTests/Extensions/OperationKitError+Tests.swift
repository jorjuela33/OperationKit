//
//  OperationKitError+Tests.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/8/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import OperationKit

extension OperationKitError {
    
    var isUnacceptableStatusCode: Bool {
        if case .unacceptableStatusCode(_) = self { return true}
        
        return false
    }
}
