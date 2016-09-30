//
//  UploadOperation.swift
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

open class UploadOperation: Operation {
    
    fileprivate var uploadTask: URLSessionDataTask?
    private var session: URLSession!
    
    /// the data returned for the server
    open fileprivate(set) var data = Data()
    
    /// the response from the host
    open var response: HTTPURLResponse? {
        return uploadTask?.response as? HTTPURLResponse
    }
    
    /// the URL for this operation
    open var url: URL? {
        return uploadTask?.originalRequest?.url
    }
    
    // MARK: Initialization
    
    public init(request: URLRequest, sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default) {
        super.init()
        
        session = Foundation.URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        uploadTask = session.dataTask(with: request)
        addCondition(ReachabilityCondition(host: request.url!))
        
        name = request.url?.absoluteString ?? "Upload operation"
    }
    
    // MARK: Overrided methods
    
    override open func execute() {
        uploadTask?.resume()
    }
    
    override open func finished(_ errors: [Error]) {
        session.invalidateAndCancel()
    }
}

extension UploadOperation: URLSessionDataDelegate {
    
    // MARK: NSURLSessionDataDelegate
    
    public func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            
            guard isCancelled == false else {
                finish()
                uploadTask?.cancel()
                return
            }
            
            completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.data.append(data)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard isCancelled == false else { return }
        
        finishWithError(error)
    }
}
