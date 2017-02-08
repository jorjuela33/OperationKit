//
//  ReachabilityCondition.swift
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
import SystemConfiguration

public protocol NetworkObservable: class {
    func reachabilityManager(manager: ReachabilityManager, didChangeToNetworkStatus status: ReachabilityManager.ReachabilityStatus)
}

public struct ReachabilityCondition: OperationCondition {
    
    public static let isMutuallyExclusive = false
    public static let hostKey = "Host"
    public static let name = "Reachability"
    
    public let host: URL
    
    public init(host: URL) {
        self.host = host
    }
    
    // MARK: OperationCondition
    
    public func dependency(for operation: Operation) -> Foundation.Operation? {
        return nil
    }
    
    public func evaluate(for operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        ReachabilityManager.requestReachability(host) { reachable in
            guard reachable else {
                let userInfo = [OperationConditionKey: type(of: self).name, ReachabilityCondition.hostKey: self.host] as [String : Any]
                let error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.conditionFailed.rawValue, userInfo: userInfo)
                completion(.failed(error))
                return
            }
            
            completion(.satisfied)
        }
    }
}

private let defaultReferenceKey = "_defaultReferenceKey"

public enum ReachabilityError: Error {
    case failedToCreateWithAddress(sockaddr_in)
    case failedToCreateWithHostname(String)
    case failedToMonitorWithHostName(String)
}

open class ReachabilityManager {
    
    private static var reachabilityRefs = [String: SCNetworkReachability]()
    private let host: String
    private var observers: [NetworkObservable] = []
    private let queue = DispatchQueue(label: "com.operations.reachability", attributes: [])
    
    open private(set) var status: ReachabilityStatus = .unknown
    
    public enum ReachabilityStatus {
        case notReachable, reachableViaWiFi, reachableViaWWAN, unknown
    }
    
    // MARK: Initialization
    
    required public init(reference: SCNetworkReachability, host: String = defaultReferenceKey) {
        self.host = host
        queue.sync {
            var reachabilityFlags: SCNetworkReachabilityFlags = []
            if SCNetworkReachabilityGetFlags(reference, &reachabilityFlags) {
                if reachabilityFlags.contains(.reachable) {
                    self.status = reachabilityFlags.contains(.isWWAN) == false ? .reachableViaWiFi : .reachableViaWWAN
                }
                else {
                    status = .notReachable
                }
            }
            
            if ReachabilityManager.reachabilityRefs.keys.contains(host) == false {
                ReachabilityManager.reachabilityRefs[host] = reference
            }
        }
    }
    
    public convenience init(host: String) throws {
        guard let ref = ReachabilityManager.reachabilityRefs[host] ?? SCNetworkReachabilityCreateWithName(nil, host.cString(using: String.Encoding.utf8)!) else {
            throw ReachabilityError.failedToCreateWithHostname(host)
        }
        
        self.init(reference: ref, host: host)
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: Instance methods
    
    /// append a new observer for the current instance of the reachability
    open func addObserver(_ observer: NetworkObservable) {
        queue.sync {
            self.observers.append(observer)
        }
    }
    
    /// remove the observer for the current instance of the reachability
    open func removeObserver(_ observer: NetworkObservable) {
        queue.sync {
            guard let index = self.observers.index(where: { $0 === observer }) else { return }
            
            self.observers.remove(at: index)
        }
    }
    
    /// Starts monitoring for changes in network reachability status.
    open func startMonitoring() throws {
        guard let reference = ReachabilityManager.reachabilityRefs[host] else {
            return
        }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged.passRetained(self).toOpaque()
        let callback = SCNetworkReachabilitySetCallback(reference, { _, reachabilityFlags, info in
            var status: ReachabilityStatus = .notReachable
            
            if reachabilityFlags.contains(.reachable) {
                status = reachabilityFlags.contains(.isWWAN) == false ? .reachableViaWiFi : .reachableViaWWAN
            }
            
            let reachability = Unmanaged<ReachabilityManager>.fromOpaque(info!).takeUnretainedValue()
            reachability.notifyObservers(status)
            
        }, &context)
        
        guard SCNetworkReachabilitySetDispatchQueue(reference, DispatchQueue.main) && callback else {
            throw ReachabilityError.failedToMonitorWithHostName(host)
        }
    }
    
    /// Stops monitoring for changes in network reachability status.
    open func stopMonitoring() {
        guard let reference = ReachabilityManager.reachabilityRefs[host] else { return }
        
        SCNetworkReachabilitySetCallback(reference, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reference, nil)
    }
    
    // MARK: Private methods
    
    private final func notifyObservers(_ status: ReachabilityStatus) {
        guard self.status != status else { return }
        
        self.status = status
        for observer in observers {
            observer.reachabilityManager(manager: self, didChangeToNetworkStatus: status)
        }
    }
    
    // MARK: Static methods
    
    open static func reachabilityForInternetConnection() throws -> ReachabilityManager {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout.size(ofValue: address))
        address.sin_family = sa_family_t(AF_INET)
        
        guard let reference = withUnsafePointer(to: &address, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else { throw ReachabilityError.failedToCreateWithAddress(address) }
        
        return ReachabilityManager(reference: reference)
    }
    
    /// Naive implementation of the reachability
    /// TODO: VPN, cellular connection.
    open static func requestReachability(_ url: URL, completionHandler: (Bool) -> Void) {
        guard let host = url.host else {
            completionHandler(false)
            return
        }
        
        do {
            let reachabilityManager = try ReachabilityManager(host: host)
            completionHandler(reachabilityManager.status != .notReachable)
        }
        catch {
            completionHandler(false)
        }
    }
}
