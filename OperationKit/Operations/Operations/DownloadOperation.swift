//
//  DownloadOperation.swift
//  beacon-ios
//
//  Created by Jorge Orjuela on 3/17/16.
//  Copyright © 2016 Stabilitas. All rights reserved.
//

import Foundation

class DownloadOperation: Operation {
    // MARK: Properties
    private let cacheFile: NSURL
    private var downloadTask: NSURLSessionTask?
    private var session: NSURLSession!
    
    var response: NSHTTPURLResponse? {
        return downloadTask?.response as? NSHTTPURLResponse
    }
    
    var URL: NSURL? {
        return downloadTask?.originalRequest?.URL
    }
    
    // MARK: Initialization
    
    init(request: NSURLRequest, cacheFile: NSURL, sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()) {
        self.cacheFile = cacheFile
        
        super.init()
        
        session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        downloadTask = session.downloadTaskWithRequest(request)
        addCondition(ReachabilityCondition(host: request.URL!))
        
        name = request.URL?.absoluteString
    }
    
    // MARK: Overrided methods
    
    override func execute() {
        downloadTask?.resume()
    }
    
    override func finished(errors: [NSError]) {
        session.invalidateAndCancel()
    }
}

extension DownloadOperation: NSURLSessionDownloadDelegate {
    
    // MARK: NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession,
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
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        guard cancelled == false else { return }
        
        finishWithError(error)
    }
}