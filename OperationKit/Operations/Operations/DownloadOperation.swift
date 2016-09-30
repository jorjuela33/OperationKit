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

open class DownloadOperation: Operation {
    
    fileprivate let cacheFile: URL
    fileprivate var downloadTask: URLSessionTask?
    private var session: Foundation.URLSession!
    
    open var response: HTTPURLResponse? {
        return downloadTask?.response as? HTTPURLResponse
    }
    
    open var url: URL? {
        return downloadTask?.originalRequest?.url
    }
    
    // MARK: Initialization
    
    public init(request: URLRequest, cacheFile: URL, sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.cacheFile = cacheFile
        
        super.init()
        
        session = Foundation.URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        downloadTask = session.downloadTask(with: request)
        addCondition(ReachabilityCondition(host: request.url!))
        
        name = request.url?.absoluteString
    }
    
    // MARK: Overrided methods
    
    override open func execute() {
        downloadTask?.resume()
    }
    
    override open func finished(_ errors: [Error]) {
        session.invalidateAndCancel()
    }
}

extension DownloadOperation: URLSessionDownloadDelegate {
    
    // MARK: NSURLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {

        do {
            try FileManager.default.removeItem(at: cacheFile)
        } catch { }
            
        do {
            try FileManager.default.moveItem(at: location, to: cacheFile)
        } catch {
            finishWithError(error)
        }
    }
    
    public func URLSession(_ session: Foundation.URLSession,
                    dataTask: URLSessionDataTask,
                    didReceiveResponse response: URLResponse,
                    completionHandler: (Foundation.URLSession.ResponseDisposition) -> Void) {
            
            guard isCancelled == false else {
                finish()
                downloadTask?.cancel()
                return
            }
            
            completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard isCancelled == false else { return }
        
        finishWithError(error)
    }
}
