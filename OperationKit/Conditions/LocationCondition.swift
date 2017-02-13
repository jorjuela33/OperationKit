//
//  LocationCondition.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/14/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

#if os(iOS)
    import CoreLocation
    import Foundation
    
    public struct LocationCondition: OperationCondition {
        
        public enum Usage {
            case always
            case whenInUse
        }
        
        public static var isMutuallyExclusive: Bool {
            return false
        }
        
        public static let name = "Location"
        public static let locationServicesEnabledKey = "CLLocationServicesEnabled"
        public static let authorizationStatusKey = "CLAuthorizationStatus"
        
        let usage: Usage
        
        public init(usage: Usage) {
            self.usage = usage
        }
        
        // MARK: OperationCondition
        
        public func dependency(for operation: OperationKit.Operation) -> Foundation.Operation? {
            return LocationPermissionOperation(usage: usage)
        }
        
        public func evaluate(for operation: OperationKit.Operation, completion: @escaping (OperationConditionResult) -> Void) {
            let enabled = CLLocationManager.locationServicesEnabled()
            let actual = CLLocationManager.authorizationStatus()
            
            var error: NSError?
            
            // There are several factors to consider when evaluating this condition
            switch (enabled, usage, actual) {
            case (true, _, .authorizedAlways), (true, .always, .authorizedWhenInUse):
                // The service is enabled, and we have "Always" permission -> condition satisfied.
                break
                
            case (true, .whenInUse, .authorizedWhenInUse):
                /*
                 The service is enabled, and we have and need "WhenInUse"
                 permission -> condition satisfied.
                 */
                break
                
            default:
                /*
                 Anything else is an error. Maybe location services are disabled,
                 or maybe we need "Always" permission but only have "WhenInUse",
                 or maybe access has been restricted or denied,
                 or maybe access hasn't been request yet.
                 
                 The last case would happen if this condition were wrapped in a `SilentCondition`.
                 */
                let userInfo: [String: Any] = [OperationConditionKey: type(of: self).name,
                                               type(of: self).locationServicesEnabledKey: enabled,
                                               type(of: self).authorizationStatusKey: Int(actual.rawValue)]
                
                error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.conditionFailed.rawValue, userInfo: userInfo)
                
            }
            
            if let error = error {
                completion(.failed(error))
            }
            else {
                completion(.satisfied)
            }
        }
    }
    
    private class LocationPermissionOperation: OperationKit.Operation {
        
        private let usage: LocationCondition.Usage
        fileprivate var manager: CLLocationManager?
        
        init(usage: LocationCondition.Usage) {
            self.usage = usage
            
            super.init()
            
            addCondition(MutuallyExclusive<AlertPresentation>())
        }
        
        // MARK: Overrided methods
        
        override func execute() {
            switch (CLLocationManager.authorizationStatus(), usage) {
            case (.notDetermined, _), (.authorizedWhenInUse, .always):
                DispatchQueue.main.async {
                    self.requestPermission()
                }
                
            default:
                finish()
            }
        }
        
        // MARK Private methods
        
        private func requestPermission() {
            manager = CLLocationManager()
            manager?.delegate = self
            
            let key: String
            
            switch usage {
            case .whenInUse:
                key = "NSLocationWhenInUseUsageDescription"
                manager?.requestWhenInUseAuthorization()
                
            case .always:
                key = "NSLocationAlwaysUsageDescription"
                manager?.requestAlwaysAuthorization()
            }
            
            assert(Bundle.main.object(forInfoDictionaryKey: key) != nil, "Requesting location permission requires the \(key) key in your Info.plist")
        }
    }
    
    extension LocationPermissionOperation: CLLocationManagerDelegate {
        
        // MARK: CLLocationManagerDelegate
        
        @objc func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if manager == self.manager && isExecuting && status != .notDetermined {
                finish()
            }
        }
    }

#endif
