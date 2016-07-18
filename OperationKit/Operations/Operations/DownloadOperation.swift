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

public class DownloadOperation: Operation {
    // MARK: Properties
    private let cacheFile: NSURL
    private var downloadTask: NSURLSessionTask?
    private var session: NSURLSession!
    
    public var response: NSHTTPURLResponse? {
        return downloadTask?.response as? NSHTTPURLResponse
    }
    
    public var URL: NSURL? {
        return downloadTask?.originalRequest?.URL
    }
    
    // MARK: Initialization
    
    public init(request: NSURLRequest, cacheFile: NSURL, sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()) {
        self.cacheFile = cacheFile
        
        super.init()
        
        session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        downloadTask = session.downloadTaskWithRequest(request)
        addCondition(ReachabilityCondition(host: request.URL!))
        
        name = request.URL?.absoluteString
    }
    
    // MARK: Overrided methods
    
    override public func execute() {
        downloadTask?.resume()
    }
    
    override public func finished(errors: [NSError]) {
        session.invalidateAndCancel()
    }
}

extension DownloadOperation: NSURLSessionDownloadDelegate {
    
    // MARK: NSURLSessionDownloadDelegate
    
    public func URLSession(session: NSURLSession,
                           downloadTask: NSURLSessionDownloadTask,
                           didFinishDownloadingToURL location: NSURL) {

        do {
            try NSFileManager.defaultManager().removeItemAtURL(cacheFile)
        } catch { }
            
        do {
            try NSFileManager.defaultManager().moveItemAtURL(location, toURL: cacheFile)
        } catch {
            finishWithError(error as NSError)
        }
    }
    
    func URLSession(session: NSURLSession,
                    dataTask: NSURLSessionDataTask,
                    didReceiveResponse response: NSURLResponse,
                    completionHandler: (NSURLSessionResponseDisposition) -> Void) {
            
            guard cancelled == false else {
                finish()
                downloadTask?.cancel()
                return
            }
            
            completionHandler(.Allow)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        guard cancelled == false else { return }
        
        finishWithError(error)
    }
}