//
//  StringResponseSerializer.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/7/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import Foundation

public struct StringResponseSerializer: ResponseSerializer {
    
    private var encoding: String.Encoding
    
    // MARK: Initialization
    
    init(encoding: String.Encoding) {
        self.encoding = encoding
    }
    
    // MARK: ResponseSerializer
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data) -> Result<String> {
        guard let response = response, emptyResponseCodes.contains(response.statusCode) else { return .success("") }
        
        guard data.count > 0 else {
            return .failure(SerializationFailure.inputDataNilOrZeroLength)
        }
        
        guard let stringResponse = String(data: data, encoding: encoding) else {
            return .failure(SerializationFailure.stringSerializationFailed(encoding: encoding))
        }
        
        return .success(stringResponse)
    }
}
