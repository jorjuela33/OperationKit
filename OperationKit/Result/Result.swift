//
//  Result.swift
//  OperationKit
//
//  Created by Jorge Orjuela on 1/7/17.
//  Copyright © 2017 Chessclub. All rights reserved.
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
}
