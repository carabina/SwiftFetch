//
//  Fetch.swift
//  SwiftFetch
//
//  Created by Yury Dymov on 3/29/17.
//  Copyright © 2017 Yury Dymov. All rights reserved.
//

import Foundation

public enum FetchResponse {
    case success(Data, Int)
    case failure(Error, Int)
}

public enum FetchError: Error {
    case badResponse
    case serverError
    case endpointIsNil
    case incompleteRequest
}

final public class Fetch {
    private var type: HTTPRequestType!
    private var endpoint: String?
    private var params: [String:AnyObject] = [:]
    private var headers: [String:String] = [:]
    private var completionBlock: ((FetchResponse) -> Void)?
    private var uploadProgressBlock: ((Int64, Int64) -> Void)?
    private var token: String?
    
    private static let defaultSession = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
    
    init(type: HTTPRequestType, endpoint: String?) {
        self.type = type
        self.endpoint = endpoint
    }
    
    public static func get(_ endpoint: String?) -> Fetch {
        return Fetch(type: .get, endpoint: endpoint)
    }
    
    public static func head(_ endpoint: String?) -> Fetch {
        return Fetch(type: .head, endpoint: endpoint)
    }
    
    public static func options(_ endpoint: String?) -> Fetch {
        return Fetch(type: .options, endpoint: endpoint)
    }
    
    public static func patch(_ endpoint: String?) -> Fetch {
        return Fetch(type: .patch, endpoint: endpoint)
    }
    
    public static func put(_ endpoint: String?) -> Fetch {
        return Fetch(type: .put, endpoint: endpoint)
    }
    
    public static func post(_ endpoint: String?) -> Fetch {
        return Fetch(type: .post, endpoint: endpoint)
    }
    
    public static func delete(_ endpoint: String?) -> Fetch {
        return Fetch(type: .delete, endpoint: endpoint)
    }
    
    public func setAuth(token: String?) -> Fetch {
        self.token = token
        
        guard let token = token else { return self }
        
        return self.setHeader(key: "Authorization", value: "Bearer \(token)")
    }
    
    public func setParam(key: String, value: Int?) -> Fetch {
        return setParam(key: key, value: value as AnyObject)
    }
    
    public func setParam(key: String, value: String?) -> Fetch {
        return setParam(key: key, value: value as AnyObject)
    }
    
    public func setParam(key: String, value: AnyObject?) -> Fetch {
        if (value == nil) {
            return self
        }
        
        self.params[key] = value!
        
        return self
    }
    
    public func addParams(_ params: [String:AnyObject]?) -> Fetch {
        self.params.merge(params)
        
        return self
    }
    
    public func setHeader(key: String, value: String?) -> Fetch {
        self.headers[key] = value
        
        return self
    }
    
    public func addHeaders(_ headers: [String:String]?) -> Fetch {
        self.headers.merge(headers)
        
        return self
    }
    
    public func setCompletionBlock(_ completionBlock: ((FetchResponse) -> Void)?) -> Fetch {
        self.completionBlock = completionBlock
        
        return self
    }
        
    public func request() -> URLRequest? {
        guard let endpoint = self.endpoint else { return nil }
        
        guard let request = Request.genericRequest(endpoint: endpoint, options: [
            "params": self.params as AnyObject,
            "headers": self.headers as AnyObject,
            "type": self.type as AnyObject])
            else {
                return nil
        }
        
        return request
    }
    
    @discardableResult
    public func execute(_ session: URLSession? = nil) -> URLSessionDataTask? {
        guard let endpoint = self.endpoint else {
            if let completionBlock = self.completionBlock {
                completionBlock(.failure(FetchError.endpointIsNil, -1))
                
                return nil
            }
            
            fatalError("completion block and endpoint are both nil, what are you expecting to happen?")
        }
        
        guard let request = Request.genericRequest(endpoint: endpoint, options: [
            "params": self.params as AnyObject,
            "headers": self.headers as AnyObject,
            "type": self.type as AnyObject]
        ) else {
            if let completionBlock = self.completionBlock {
                completionBlock(.failure(FetchError.incompleteRequest, -1))
                
                return nil
            }
                
            fatalError("completion block is nil and reqiest is incomplete, what are you expecting to happen?")
        }
        
        let task = (session ?? Fetch.defaultSession).dataTask(with: request) { (data, response, error) in
            guard let completionBlock = self.completionBlock else { return }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                return completionBlock(.failure(error ?? FetchError.badResponse, -1))
            }
            
            if let error = error {
                return completionBlock(.failure(error, statusCode))
            }
            
            if statusCode < 200 || statusCode >= 300 {
                return completionBlock(.failure(error ?? FetchError.serverError, statusCode))
            }
            
            completionBlock(.success(data ?? Data(), statusCode))
        }
        
        task.resume()
        
        return task
    }
    
}
