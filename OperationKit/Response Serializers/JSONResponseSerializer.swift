//
//  JSONResponseSerializer.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/7/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import Foundation

public struct JSONResponseSerializer: ResponseSerializer {
    
    private var readingOptions: JSONSerialization.ReadingOptions
    
    // MARK: Initialization
    
    init(readingOptions: JSONSerialization.ReadingOptions) {
        self.readingOptions = readingOptions
    }
    
    // MARK: ResponseSerializer
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data) -> Result<Any> {
        guard let response = response, emptyResponseCodes.contains(response.statusCode) == false else { return .success(NSNull()) }
        
        guard data.count > 0 else {
            return .failure(OperationKitError.inputDataNilOrZeroLength)
        }
        
        do {
            let serializedObject = try JSONSerialization.jsonObject(with: data, options: readingOptions)
            return .success(serializedObject)
        }
        catch {
            return .failure(OperationKitError.jsonSerializationFailed(error: error))
        }
    }
}
