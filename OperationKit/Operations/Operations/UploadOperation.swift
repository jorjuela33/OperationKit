//
//  UploadOperation.swift
//  beacon-ios
//
//  Created by Jorge Orjuela on 3/17/16.
//  Copyright © 2016 Stabilitas. All rights reserved.
//

import Foundation

class UploadOperation: Operation {
    
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
    
    init(request: NSURLRequest, sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()) {
        super.init()
        
        session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        uploadTask = session.dataTaskWithRequest(request)
        addCondition(ReachabilityCondition(host: request.URL!))
        
        name = request.URL?.absoluteString ?? "Upload operation"
    }
    
    // MARK: Overrided methods
    
    override func execute() {
        uploadTask?.resume()
    }
    
    override func finished(errors: [NSError]) {
        session.invalidateAndCancel()
    }
}

extension UploadOperation: NSURLSessionDataDelegate {
    
    // MARK: NSURLSessionDataDelegate
    
    func URLSession(session: NSURLSession,
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
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.data.appendData(data)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        guard cancelled == false else { return }
        
        finishWithError(error)
    }
}