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

public struct ReachabilityCondition: OperationCondition {
    
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
}

open class ReachabilityManager {
    
    private static var reachabilityRefs = [String: SCNetworkReachability]()
    private let queue = DispatchQueue(label: "com.operations.reachability", attributes: [])
    
    open private(set) var status: ReachabilityStatus = .notReachable
    
    public enum ReachabilityStatus {
        case notReachable, reachableViaWiFi, reachableViaWWAN
    }
    
    // MARK: Initialization 
    
    required public init(reference: SCNetworkReachability, host: String = defaultReferenceKey) {
        queue.sync {
            var reachabilityFlags: SCNetworkReachabilityFlags = []
            if SCNetworkReachabilityGetFlags(reference, &reachabilityFlags) {
                guard reachabilityFlags.contains(.reachable) else { return }
                
                self.status = reachabilityFlags.contains(.isWWAN) == false ? .reachableViaWiFi : .reachableViaWWAN
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
