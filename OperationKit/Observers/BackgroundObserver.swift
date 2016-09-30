//
//  BackgroundObserver.swift
//  beacon-ios
//
//  Created by Jorge Orjuela on 3/21/16.
//  Copyright © 2016 Stabilitas. All rights reserved.
//

import Foundation
import UIKit

public final class BackgroundObserver: NSObject {
    
    private var identifier = UIBackgroundTaskInvalid
    private var isInBackground = false
    
    // MARK: Initialization
    
    public override init() {
        super.init()
        
        setupNotifications()
        
        isInBackground = UIApplication.shared.applicationState == .background
        
        if isInBackground {
            startBackgroundTask()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Notification methods
    
    func applicationDidEnterBackground(_ notification: Notification) {
        isInBackground = true
        
        startBackgroundTask()
    }
    
    func applicationWillEnterForeground(_ notification: Notification) {
        isInBackground = false
        endBackgroundTask()
    }
    
    // MARK: Private methods
    
    fileprivate func endBackgroundTask() {
        guard identifier != UIBackgroundTaskInvalid else { return }

        UIApplication.shared.endBackgroundTask(identifier)
        identifier = UIBackgroundTaskInvalid
    }
    
    private final func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground(_:)),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground(_:)),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive,
                                               object: nil)
    }
    
    private func startBackgroundTask() {
        guard identifier == UIBackgroundTaskInvalid else { return }

        identifier = UIApplication.shared.beginBackgroundTask(withName: "BackgroundObserver", expirationHandler: {
            self.endBackgroundTask()
        })
    }
}

extension BackgroundObserver: ObservableOperation {
    
    // MARK: ObservableOperation
    
    public func operationDidStart(_ operation: Operation) {  /* No Op */ }
    
    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) { /* No Op */ }
    
    public func operationDidFinish(_ operation: Operation, errors: [Error]) {
        endBackgroundTask()
    }
}
