//
//  DownloadOperation.swift
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

open class DownloadRequestOperation: URLRequestOperation {
    
    fileprivate let cacheFile: URL
    fileprivate var progressHandler: ((Progress) -> Void)?
    
    /// the progress for the operation
    public let progress = Progress(totalUnitCount: 1)
    
    // MARK: Initialization
    
    public init(request: URLRequest, cacheFile: URL, sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.cacheFile = cacheFile
        
        super.init(request: request, configuration: sessionConfiguration)
        
        sessionTask = session.downloadTask(with: request)
    }
    
    // MARK: Instance methods
    
    /// reports the progress for the task
    public final func downloadProgress(_ progressHandler: ((Progress) -> Void)?) -> Self {
        self.progressHandler = progressHandler
        return self
    }
}

extension DownloadRequestOperation {
    
    // MARK: Response Serialization
    
    /// Returns a object contained in a result type constructed from the response serializer passed as parameter.
    public func response<Serializer: ResponseSerializer, T>(cacheFile: URL,
                         responseSerializer: Serializer,
                         completionHandler: @escaping ((Result<Serializer.SerializedValue>) -> ())) -> Self where Serializer.SerializedValue == T {
        
        let blockOperation = BlockOperation { [unowned self] in
            guard let data = try? Data(contentsOf: cacheFile) else {
                completionHandler(.failure(OperationKitError.inputDataNil))
                return
            }
            
            let result = responseSerializer.serialize(request: self.sessionTask.originalRequest, response: self.response, data: data)
            
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
        
        addSubOperation(blockOperation)
        return self
    }
    
    /// Adds a handler to be called once the request has finished.
    public func responseData(_ completionHandler: @escaping ((Result<Data>) -> ())) -> Self {
        return response(cacheFile: cacheFile, responseSerializer: DataResponseSerializer(), completionHandler: completionHandler)
    }
    
    /// Returns a JSON object contained in a result type constructed from the response data using `JSONSerialization`
    /// with the specified reading options.
    public func responseJSON(readingOptions: JSONSerialization.ReadingOptions = .allowFragments, completionHandler: @escaping ((Result<Any>) -> ())) -> Self {
        return response(cacheFile: cacheFile, responseSerializer: JSONResponseSerializer(readingOptions: readingOptions), completionHandler: completionHandler)
    }
    
    /// Returns a string object contained in a result type constructed from the response data using `String.Encoding`
    /// with the specified encoding options.
    public func responseString(encoding: String.Encoding = .utf8, completionHandler: @escaping ((Result<String>) -> ())) -> Self {
        return response(cacheFile: cacheFile, responseSerializer: StringResponseSerializer(encoding: .utf8), completionHandler: completionHandler)
    }
}

extension DownloadRequestOperation: URLSessionDownloadDelegate {
    
    // MARK: NSURLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        
        progress.completedUnitCount = totalBytesWritten
        progress.totalUnitCount = totalBytesExpectedToWrite
        progressHandler?(progress)
    }
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64,
                           expectedTotalBytes: Int64) {
        
        _progress.completedUnitCount = fileOffset
        _progress.totalUnitCount = expectedTotalBytes
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        try? FileManager.default.removeItem(at: cacheFile)
            
        do {
            try FileManager.default.moveItem(at: location, to: cacheFile)
        } catch {
            aggregate(error)
        }
    }
}
