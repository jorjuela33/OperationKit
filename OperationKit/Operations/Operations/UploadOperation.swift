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

public class UploadOperation: Operation {
    
    // MARK: Properties
    private var uploadTask: NSURLSessionDataTask?
    private var session: NSURLSession!
    
    /// the data returned for the server
    private(set) var data = NSMutableData()
    
    /// the response from the host
    var response: NSHTTPURLResponse? {
        return uploadTask?.response as? NSHTTPURLResponse
    }
    
    /// the URL for this operation
    var URL: NSURL? {
        return uploadTask?.originalRequest?.URL
    }
    
    // MARK: Initialization
    
    public init(request: NSURLRequest, sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()) {
        super.init()
        
        session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        uploadTask = session.dataTaskWithRequest(request)
        addCondition(ReachabilityCondition(host: request.URL!))
        
        name = request.URL?.absoluteString ?? "Upload operation"
    }
    
    // MARK: Overrided methods
    
    override public func execute() {
        uploadTask?.resume()
    }
    
    override public func finished(errors: [NSError]) {
        session.invalidateAndCancel()
    }
}

extension UploadOperation: NSURLSessionDataDelegate {
    
    // MARK: NSURLSessionDataDelegate
    
    public func URLSession(session: NSURLSession,
                    dataTask: NSURLSessionDataTask,
                    didReceiveResponse response: NSURLResponse,
                    completionHandler: (NSURLSessionResponseDisposition) -> Void) {
            
            guard cancelled == false else {
                finish()
                uploadTask?.cancel()
                return
            }
            
            completionHandler(.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.data.appendData(data)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        guard cancelled == false else { return }
        
        finishWithError(error)
    }
}