//
//  URLDataRequestOperation.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/7/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import Foundation

open class DataRequestOperation: URLRequestOperation {
    
    /// the data returned for the server
    fileprivate(set) var data = Data()
}

extension DataRequestOperation {
    
    // MARK: Response Serialization
    
    /// Returns a object contained in a result type constructed from the response serializer passed as parameter.
    public func response<Serializer: ResponseSerializer, T>(data: Data,
                         responseSerializer: Serializer,
                         completionHandler: @escaping ((Result<Serializer.SerializedValue>) -> ())) -> Self where Serializer.SerializedValue == T {
        let blockOperation = BlockOperation { [unowned self] in
            let result = responseSerializer.serialize(request: self.sessionTask.originalRequest, response: self.response, data: self.data)
            
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
        
        addSubOperation(blockOperation)
        return self
    }
    
    /// Adds a handler to be called once the request has finished.
    public func responseData(_ completionHandler: @escaping ((Result<Data>) -> ())) -> Self {
        return response(data: data, responseSerializer: DataResponseSerializer(), completionHandler: completionHandler)
    }
    
    /// Returns a JSON object contained in a result type constructed from the response data using `JSONSerialization`
    /// with the specified reading options.
    public func responseJSON(readingOptions: JSONSerialization.ReadingOptions = .allowFragments, completionHandler: @escaping ((Result<Any>) -> ())) -> Self {
        return response(data: data, responseSerializer: JSONResponseSerializer(readingOptions: readingOptions), completionHandler: completionHandler)
    }
    
    /// Returns a string object contained in a result type constructed from the response data using `String.Encoding`
    /// with the specified encoding options.
    public func responseString(encoding: String.Encoding = .utf8, completionHandler: @escaping ((Result<String>) -> ())) -> Self {
        return response(data: data, responseSerializer: StringResponseSerializer(encoding: .utf8), completionHandler: completionHandler)
    }
}

extension DataRequestOperation: URLSessionDataDelegate {
    
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
}
