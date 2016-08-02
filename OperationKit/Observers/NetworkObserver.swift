//
//  NetworkObserver.swift
//  beacon-ios
//
//  Created by Jorge Orjuela on 3/21/16.
//  Copyright © 2016 Stabilitas. All rights reserved.
//

import UIKit

public struct NetworkObserver: ObservableOperation {
    
    // MARK: Initializer
    
    public init() {}
    
    // MARK: ObservableOperation
    
    public func operationDidStart(operation: Operation) {
        dispatch_async(dispatch_get_main_queue()) {
            NetworkIndicatorManager.sharedIndicatorController.networkActivityDidStart()
        }
    }
    
    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) { }
    
    public func operationDidFinish(operation: Operation, errors: [NSError]) {
        dispatch_async(dispatch_get_main_queue()) {
            NetworkIndicatorManager.sharedIndicatorController.networkActivityDidEnd()
        }
    }
}

private class NetworkIndicatorManager {
    // MARK: Properties
    
    static let sharedIndicatorController = NetworkIndicatorManager()
    private var activityCount = 0
    private var cancelled = false
    
    // MARK: Instance methods
    
    func networkActivityDidStart() {
        assert(NSThread.isMainThread())
        
        activityCount += 1
        updateIndicatorVisibility()
    }
    
    func networkActivityDidEnd() {
        assert(NSThread.isMainThread())
        
        activityCount -= 1
        updateIndicatorVisibility()
    }
    
    // MARK: Private methods
    
    private func hideIndicator() {
        cancelled = true
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    private func showIndicator() {
        cancelled = false
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    private func updateIndicatorVisibility() {
        if activityCount > 0 {
            showIndicator()
        } else {
            let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)))
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                guard self.cancelled == false else { return }
                
                self.hideIndicator()
            })
        }
    }
}