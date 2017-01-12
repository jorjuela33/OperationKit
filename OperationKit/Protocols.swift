//
//  Protocols.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/7/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import Foundation

let emptyResponseCodes = [204, 205]

public enum OperationKitError: Error {
    case inputDataNil
    case inputDataNilOrZeroLength
    case stringSerializationFailed(encoding: String.Encoding)
    case jsonSerializationFailed(error: Error)
    case unacceptableStatusCode(code: Int)
}

public protocol ResponseSerializer {
    associatedtype SerializedValue
    
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data) -> Result<SerializedValue>
}
