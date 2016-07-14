//
//  ParameterEncoding.swift
//  NetworkOperation
//
//  Created by Jorge Orjuela on 3/13/16.
//  Copyright © 2016 Jorge. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case DELETE, GET, POST, PUT
}

enum ParameterEncoding {
    case JSON
    case URL
    
    // MARK: Instance methods
    
    /// Creates a URL request by encoding parameters and applying them onto an existing request.
    ///
    /// URLRequest - The request to have parameters applied
    /// parameters - The parameters to apply
    func encode(request: NSURLRequest, parameters: AnyObject?) -> (NSURLRequest, NSError?) {
        guard let
            // The parameters
            parameters = parameters,
            
            // MutableURLRequest
            mutableURLRequest = request.mutableCopy() as? NSMutableURLRequest else {
                
                return (request, nil)
        }
        
        var encodingError: NSError?
        
        switch self {
        case .JSON:
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(parameters, options: .PrettyPrinted)
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                mutableURLRequest.HTTPBody = data
            } catch {
                encodingError = error as NSError
            }
            
        case .URL:
            guard let parameters = parameters as? JSONDictionary else { fatalError("array parameters is not implemented yet") }
            
            if let method = HTTPMethod(rawValue: mutableURLRequest.HTTPMethod) where allowEncodingInURL(method) {
                if let URLComponents = NSURLComponents(URL: mutableURLRequest.URL!, resolvingAgainstBaseURL: false) {
                    let percentEncodedQuery = (URLComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + queryString(parameters)
                    URLComponents.percentEncodedQuery = percentEncodedQuery
                    mutableURLRequest.URL = URLComponents.URL
                }
            }
            else {
                mutableURLRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                mutableURLRequest.HTTPBody = queryString(parameters).dataUsingEncoding(NSUTF8StringEncoding)
            }
            
        }
        
        return (mutableURLRequest, encodingError)
    }
    
    // MARK: Private methods
    
    private func allowEncodingInURL(method: HTTPMethod) -> Bool {
        switch method {
        case .GET, .DELETE:
            return true
        default:
            return false
        }
    }
    
    private func queryString(parameters: [String: AnyObject]) -> String {
        var components: [String] = []
        
        for key in parameters.keys.sort(<) {
            guard let component = parameters[key] else { continue }
            
            components += queryComponent(key, component: component)
        }
        
        return components.joinWithSeparator("&")
    }
    
    private func queryComponent(key: String, component: AnyObject) -> [String] {
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
    
    private func scape(string: String) -> String {
        let allowedCharacterSet = NSCharacterSet(charactersInString:" =\"#%/<>?@\\^`{}[]|&+").invertedSet
        return string.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? string
    }
}