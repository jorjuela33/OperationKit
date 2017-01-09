//
//  URLRequestOperation+Tests.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/9/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import Foundation
@testable import OperationKit

extension URLRequestOperation {
    
    convenience init(request: URLRequest, sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.init(request: request, configuration: sessionConfiguration)
        sessionTask = session.dataTask(with: request)
    }
}
