//
//  NetworkObserver.swift
//  beacon-ios
//
//  Created by Jorge Orjuela on 3/21/16.
//  Copyright © 2016 Stabilitas. All rights reserved.
//

import UIKit

public struct NetworkObserver: ObservableOperation {
    
    private let networkIndicatorManager: NetworkIndicatorManager
    
    // MARK: Initializer
    
    public init(networkIndicatorManager: NetworkIndicatorManager) {
        self.networkIndicatorManager = networkIndicatorManager
    }
    
    // MARK: ObservableOperation
    
    public func operationDidStart(_ operation: Operation) {
        DispatchQueue.main.async {
            self.networkIndicatorManager.networkActivityDidStart()
        }
    }
    
    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) { }
    
    public func operationDidFinish(_ operation: Operation, errors: [Error]) {
        DispatchQueue.main.async {
            self.networkIndicatorManager.networkActivityDidEnd()
        }
    }
}

public class NetworkIndicatorManager {
    
    private var activityCount = 0
    private var networkIndicatorObserver: NetworkIndicatorObserver
    private var cancelled = false
    
    // MARK: Initialization
    
    init(networkIndicatorObserver: NetworkIndicatorObserver) {
        self.networkIndicatorObserver = networkIndicatorObserver
    }
    
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
        networkIndicatorObserver.isNetworkActivityIndicatorVisible = false
    }
    
    private func showIndicator() {
        cancelled = false
        networkIndicatorObserver.isNetworkActivityIndicatorVisible = true
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
