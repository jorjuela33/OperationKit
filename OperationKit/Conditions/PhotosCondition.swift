//
//  PhotosCondition.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/14/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

#if os(iOS)
    
    import Foundation
    import Photos
    
    public struct PhotosCondition: OperationCondition {
        
        public static var isMutuallyExclusive: Bool {
            return false
        }
        
        public static let name = "Photos"
        
        public init() { }
        
        // MARK: OperationCondition
        
        public func dependency(for operation: Operation) -> Foundation.Operation? {
            return PhotosPermissionOperation()
        }
        
        public func evaluate(for operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                completion(.satisfied)
                
            default:
                let userInfo = [OperationConditionKey: type(of: self).name]
                let error = NSError(domain: OperationErrorDomainCode, code: OperationErrorCode.conditionFailed.rawValue, userInfo: userInfo)
                completion(.failed(error))
            }
        }
    }
    
    /**
     A private `Operation` that will request access to the user's Photos, if it
     has not already been granted.
     */
    private class PhotosPermissionOperation: Operation {
        override init() {
            super.init()
            
            addCondition(AlertPresentation())
        }
        
        override func execute() {
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined:
                DispatchQueue.main.async {
                    PHPhotoLibrary.requestAuthorization { status in
                        self.finish()
                    }
                }
                
            default:
                finish()
            }
        }
        
    }
    
#endif
