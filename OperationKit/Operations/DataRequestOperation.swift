//
//  URLDataRequestOperation.swift
//
//  Copyright © 2016. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

open class DataRequestOperation: URLRequestOperation {
    
    /// the data returned for the server
    fileprivate(set) var data = Data()
    
    // MARK: Initialization
    
    public init(request: URLRequest, sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default) {
        super.init(request: request, configuration: sessionConfiguration)
        
        sessionTask = session.dataTask(with: request)
    }
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
