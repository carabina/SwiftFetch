//
//  Request.swift
//  SwiftFetch
//
//  Created by Yury Dymov on 3/29/17.
//  Copyright © 2017 Yury Dymov. All rights reserved.
//

import Foundation

enum HTTPRequestType: String {
    case get = "GET"
    case head = "HEAD"
    case options = "OPTIONS"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

final class Request {
    static func get(endpoint: String, options: [String: AnyObject]?) -> URLRequest? {
        return genericRequest(endpoint: endpoint, options: ["type": HTTPRequestType.get as AnyObject].extend(options))
    }
    
    static func head(endpoint: String, options: [String: AnyObject]?) -> URLRequest? {
        return genericRequest(endpoint: endpoint, options: ["type": HTTPRequestType.head as AnyObject].extend(options))
    }
    
    static func options(endpoint: String, options: [String: AnyObject]?) -> URLRequest? {
        return genericRequest(endpoint: endpoint, options: ["type": HTTPRequestType.options as AnyObject].extend(options))
    }
    
    static func post(endpoint: String, options: [String: AnyObject]?) -> URLRequest? {
        return genericRequest(endpoint: endpoint, options: ["type": HTTPRequestType.post as AnyObject].extend(options))
    }
    
    static func put(endpoint: String, options: [String: AnyObject]?) -> URLRequest? {
        return genericRequest(endpoint: endpoint, options: ["type": HTTPRequestType.put as AnyObject].extend(options))
    }
    
    static func delete(endpoint: String, options: [String: AnyObject]?) -> URLRequest? {
        return genericRequest(endpoint: endpoint, options: ["type": HTTPRequestType.delete as AnyObject].extend(options))
    }
    
    static func patch(endpoint: String, options: [String: AnyObject]?) -> URLRequest? {
        return genericRequest(endpoint: endpoint, options: ["type": HTTPRequestType.patch as AnyObject].extend(options))
    }
    
    static func genericRequest(endpoint: String, options: [String: AnyObject]) -> URLRequest? {
        guard let type = options["type"] else { return nil }
        guard type is HTTPRequestType else { return nil }
        
        switch type as! HTTPRequestType {
        case .get, .head, .options:
            return bodylessRequest(endpoint, options)
        default:
            return bodyRequest(endpoint, options)
        }
    }
    
    private static func bodylessRequest(_ endpoint: String, _ options: [String: AnyObject]) -> URLRequest? {
        let params = options["params"] as? [String: AnyObject]
        guard let url = urlFrom(endpoint: endpoint, queryParams: params) else { return nil }
        
        let req = NSMutableURLRequest(url: url)
        
        req.httpMethod = (options["type"] as! HTTPRequestType).rawValue
        
        return (req.appendHeaders(options["headers"] as? [String:String])) as URLRequest
    }
    
    private static func bodyRequest(_ endpoint: String, _ options: [String: AnyObject]) -> URLRequest? {
        guard let url = URL(string: endpoint) else { return nil }
        
        let req = NSMutableURLRequest(url: url)
        
        req.httpMethod = (options["type"] as! HTTPRequestType).rawValue
        
        return (req
            .appendHeaders(options["headers"] as? [String:String])
            .appendBody(options["params"] as? [String:AnyObject])
        ) as URLRequest
    }
}

private extension NSMutableURLRequest {
    func appendHeaders(_ headers: [String:String]?) -> NSMutableURLRequest {
        headers?.keys.forEach({ key in self.addValue(headers![key]!, forHTTPHeaderField: key) })
        
        if (self.value(forHTTPHeaderField: "Content-Type") == nil) {
            self.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if (self.value(forHTTPHeaderField: "Cache-Control") == nil) {
            self.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        }
        
        return self
    }
    
    func appendBody(_ params: [String:AnyObject]?) -> NSMutableURLRequest {
        guard let unwrappedParams = params else { return self }
        
        let contentType = self.value(forHTTPHeaderField: "Content-Type") ?? "json"
        
        if (contentType.range(of: "json") != nil
            ) {
            do {
                self.httpBody = try JSONSerialization.data(withJSONObject: unwrappedParams, options: .prettyPrinted)
            } catch {
                
            }
        } else if (contentType.range(of: "form-urlencoded") != nil) {
            var filtered:[String:String] = [:]
            
            params?.forEach({ (key, value) in
                if (value is String) {
                    filtered[key] = value as? String
                } else if (value is Int) {
                    let nvalue = value as! Int
                    filtered[key] = String(nvalue)
                } else {
                    filtered[key] = String(describing: value)
                }
            })
            
            self.httpBody = filtered.keys.map({ key in
                let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                let escapedValue = filtered[key]!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                
                return "\(escapedKey)=\(escapedValue)"
            }).joined(separator: "&").data(using: .utf8)
        } else {
            let boundaryConstant = "Boundary-" + String(Date().timeIntervalSince1970)
            let contentType = "multipart/form-data; boundary=" + boundaryConstant
            let requestBodyData : NSMutableData = NSMutableData()
            
            params?.forEach({ key, value in
                if (key.first == "_") {
                    return
                }
                
                let boundaryStart = "--\(boundaryConstant)\r\n".data(using: .utf8)!
                
                if (value is URL) {
                    let fileURL: URL = value as! URL
                    let filename = (params!["_filename"] as? String) ?? "empty"
                    let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!
                    let contentTypeString = "Content-Type: \(fileURL.mimeType())\r\n\r\n".data(using: .utf8)!
                    
                    do {
                        requestBodyData.append(boundaryStart)
                        requestBodyData.append(contentDispositionString)
                        requestBodyData.append(contentTypeString)
                        requestBodyData.append(try Data(contentsOf: fileURL))
                        requestBodyData.append("\r\n".data(using: .utf8)!)
                    } catch {
                    }
                } else if (value is Data) {
                    let data = value as! Data
                    let filename = (params!["_filename"] as? String) ?? "empty"
                    let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!
                    let contentTypeString = "Content-Type: \(data.mimeType())\r\n\r\n".data(using: .utf8)!
                    
                    requestBodyData.append(boundaryStart)
                    requestBodyData.append(contentDispositionString)
                    requestBodyData.append(contentTypeString)
                    requestBodyData.append(data)
                    requestBodyData.append("\r\n".data(using: .utf8)!)
                } else {
                    let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\"\r\n".data(using: .utf8)!
                    let contentTypeString = "Content-Type: text/plain\r\n\r\n".data(using: .utf8)!
                    let valueString: String = value as! String
                    
                    requestBodyData.append(boundaryStart)
                    requestBodyData.append(contentDispositionString)
                    requestBodyData.append(contentTypeString)
                    requestBodyData.append(valueString.data(using: .utf8)!)
                    requestBodyData.append("\r\n".data(using: .utf8)!)
                }
            })
            
            let boundaryEnd = "--\(boundaryConstant)--\r\n".data(using: .utf8)!
            
            requestBodyData.append(boundaryEnd)
            
            self.httpBody = requestBodyData as Data
            self.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        return self
    }
}

extension Request {
    public static func urlFrom(endpoint: String, queryParams: [String:AnyObject]?) -> URL? {
        var urlString = endpoint
        
        if let params = queryParams {
            var encodedKeyValueParams = [String]()
            for (key, value) in params {
                if let encodedKeyValuePair = encodeKeyValuePair(key: key, value: value) {
                    encodedKeyValueParams.append(encodedKeyValuePair)
                }
            }
            
            if encodedKeyValueParams.count > 0 {
                urlString += "?\(encodedKeyValueParams.joined(separator: "&"))"
            }
        }
        
        return URL(string: urlString)
    }

    private static func encodeKeyValuePair(key: String, value: AnyObject) -> String? {
        var encodedValue: String?
        var characterSet = CharacterSet.urlQueryAllowed
        
        characterSet.insert(charactersIn: ":/")
        
        if let value = value as? String {
            encodedValue = value.addingPercentEncoding(withAllowedCharacters: characterSet)
        } else if let value = value as? Int {
            encodedValue = String(value).addingPercentEncoding(withAllowedCharacters: characterSet)
        } else if let value = value as? Double {
            encodedValue = String(value).addingPercentEncoding(withAllowedCharacters: characterSet)
        } else if (value is [AnyObject]) {
            var encodedValues = [String]()
            let keyValue = key + "[]".addingPercentEncoding(withAllowedCharacters: characterSet)!
            (value as! [AnyObject]).forEach({ (val) in
                if let encodedValue = encodeKeyValuePair(key: keyValue, value: val) {
                    encodedValues.append(encodedValue)
                }
            })
            
            return encodedValues.joined(separator: "&")
        }
        
        if encodedValue != nil {
            return "\(key)=\(encodedValue!)"
        }
        
        return nil
    }
}

