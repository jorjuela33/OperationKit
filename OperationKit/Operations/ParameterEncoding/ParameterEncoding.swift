//
//  ParameterEncoding.swift
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

public enum HTTPMethod: String {
    case DELETE, GET, POST, PUT
}

public enum ParameterEncoding {
    case json
    case url
    
    // MARK: Instance methods
    
    /// Creates a URL request by encoding parameters and applying them onto an existing request.
    ///
    /// URLRequest - The request to have parameters applied
    /// parameters - The parameters to apply
    func encode(request: URLRequest, parameters: AnyObject?) -> (URLRequest, NSError?) {
        guard let parameters = parameters else {
            return (request, nil)
        }
        
        var encodingError: NSError?
        var mutableURLRequest = request
        
        switch self {
        case .json:
            do {
                let data = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                mutableURLRequest.httpBody = data
            } catch {
                encodingError = error as NSError
            }
            
        case .url:
            guard let parameters = parameters as? [String: AnyObject] else { fatalError("array parameters is not implemented yet") }
            
            if let method = HTTPMethod(rawValue: mutableURLRequest.httpMethod!), allowEncodingInURL(method) {
                if var URLComponents = URLComponents(url: mutableURLRequest.url!, resolvingAgainstBaseURL: false) {
                    let percentEncodedQuery = (URLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + queryString(parameters)
                    URLComponents.percentEncodedQuery = percentEncodedQuery
                    mutableURLRequest.url = URLComponents.url
                }
            }
            else {
                mutableURLRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                mutableURLRequest.httpBody = queryString(parameters).data(using: String.Encoding.utf8)
            }
            
        }
        
        return (mutableURLRequest, encodingError)
    }
    
    // MARK: Private methods
    
    private func allowEncodingInURL(_ method: HTTPMethod) -> Bool {
        switch method {
        case .GET, .DELETE:
            return true
        default:
            return false
        }
    }
    
    private func queryString(_ parameters: [String: AnyObject]) -> String {
        var components: [String] = []
        
        for key in parameters.keys.sorted(by: <) {
            guard let component = parameters[key] else { continue }
            
            components += queryComponent(key, component: component)
        }
        
        return components.joined(separator: "&")
    }
    
    private func queryComponent(_ key: String, component: AnyObject) -> [String] {
        var components: [String] = []
        
        if let dictionary = component as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponent("\(key)[\(nestedKey)]", component: value)
            }
        } else if let array = component as? [AnyObject] {
            for value in array {
                components += queryComponent("\(key)[]", component: value)
            }
        } else {
            components.append("\(scape(key))=\(scape("\(component)"))")
        }
        
        return components
    }
    
    private func scape(_ string: String) -> String {
        let allowedCharacterSet = CharacterSet(charactersIn:" =\"#%/<>?@\\^`{}[]|&+").inverted
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    }
}
