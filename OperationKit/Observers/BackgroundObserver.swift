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
    // MARK: Properties
    
    private var identifier = UIBackgroundTaskInvalid
    private var isInBackground = false
    
    // MARK: Initialization
    
    public override init() {
        super.init()
        
        setupNotifications()
        
        isInBackground = UIApplication.sharedApplication().applicationState == .Background
        
        if isInBackground {
            startBackgroundTask()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Notification methods
    
    func applicationDidEnterBackground(notification: NSNotification) {
        isInBackground = true
        
        startBackgroundTask()
    }
    
    func applicationWillEnterForeground(notification: NSNotification) {
        isInBackground = false
        endBackgroundTask()
    }
    
    // MARK: Private methods
    
    private func endBackgroundTask() {
        guard identifier != UIBackgroundTaskInvalid else { return }

        UIApplication.sharedApplication().endBackgroundTask(identifier)
        identifier = UIBackgroundTaskInvalid
    }
    
    private final func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    private func startBackgroundTask() {
        guard identifier == UIBackgroundTaskInvalid else { return }

        identifier = UIApplication.sharedApplication().beginBackgroundTaskWithName("BackgroundObserver", expirationHandler: {
            self.endBackgroundTask()
        })
    }
}

extension BackgroundObserver: ObservableOperation {
    
    // MARK: ObservableOperation
    
    public func operationDidStart(operation: Operation) {  /* No Op */ }
    
    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) { /* No Op */ }
    
    public func operationDidFinish(operation: Operation, errors: [NSError]) {
        endBackgroundTask()
    }
}