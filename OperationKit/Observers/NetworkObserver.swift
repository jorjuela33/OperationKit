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
    
    public func operationDidStart(_ operation: Operation) {
        DispatchQueue.main.async {
            NetworkIndicatorManager.sharedIndicatorController.networkActivityDidStart()
        }
    }
    
    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) { }
    
    public func operationDidFinish(_ operation: Operation, errors: [Error]) {
        DispatchQueue.main.async {
            NetworkIndicatorManager.sharedIndicatorController.networkActivityDidEnd()
        }
    }
}

private class NetworkIndicatorManager {
    
    static let sharedIndicatorController = NetworkIndicatorManager()
    private var activityCount = 0
    private var cancelled = false
    
    // MARK: Instance methods
    
    func networkActivityDidStart() {
        assert(Thread.isMainThread)
        
        activityCount += 1
        updateIndicatorVisibility()
    }
    
    func networkActivityDidEnd() {
        assert(Thread.isMainThread)
        
        activityCount -= 1
        updateIndicatorVisibility()
    }
    
    // MARK: Private methods
    
    private func hideIndicator() {
        cancelled = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    private func showIndicator() {
        cancelled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    private func updateIndicatorVisibility() {
        if activityCount > 0 {
            showIndicator()
        } else {
            let dispatchTime = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                guard self.cancelled == false else { return }
                
                self.hideIndicator()
            })
        }
    }
}
