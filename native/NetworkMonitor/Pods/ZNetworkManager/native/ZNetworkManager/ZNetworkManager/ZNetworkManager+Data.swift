//
//  ZNetworkManager+Data.swift
//  ZNetworkManager
//
//  Created by Rahul T on 23/11/17.
//  Copyright © 2017 Rahul T. All rights reserved.
//

import Foundation

extension ZNetworkManager {
    
    /// call this methdod for sending request
    ///
    /// - Parameters:
    ///   - method: POST/GET
    ///   - url: API request URL
    ///   - params: API params as Dictionary
    ///   - delegate: delegate for callbacks
    ///   - identifier: identifier for the request to identify the caller
    ///   - progressDataHandler: progress of data returned as completion block
    ///   - progressPercentageHandler: progress percentage returned as completion block
    ///   - completionHandler: completion returned as completion block
    
    @discardableResult
    public func sendRequestURL(method: ZHTTPMethod, url: String, authorization: String? = nil, headerParams: Dictionary<String, String>? = nil, params: Dictionary<String, Any>?,  isMultipartData: Bool = false, priority: ZTaskPriority = .medium , delegate:ZTaskDelegate?, metadata: ZNetworkMetaData? = nil, identifier: String?, requestRedirectionHandler: ((_ originalRequest: URLRequest,_ newRequest: URLRequest) -> ())? = nil, completionHandler:((Data, URLResponse?, String?, Error?, Int) ->())?) -> Int {
        
        var request: URLRequest = URLRequest(url: URL.init(string:url.encodeURL())!)
        request.httpMethod = method.rawValue
        
        return send(request: request, authorization: authorization, headerParams: headerParams, params: params, isMultipartData: isMultipartData, priority: priority, delegate: delegate, metadata: metadata, identifier: identifier, requestRedirectionHandler: requestRedirectionHandler, completionHandler: completionHandler)
    }
    
    @discardableResult
    public func send(request: URLRequest, authorization: String? = nil, headerParams: Dictionary<String, String>? = nil, params: Dictionary<String, Any>?, isMultipartData: Bool = false, priority: ZTaskPriority = .medium ,delegate:ZTaskDelegate?, metadata: ZNetworkMetaData? = nil, identifier: String?, requestRedirectionHandler: ((_ originalRequest: URLRequest,_ newRequest: URLRequest) -> ())? = nil, completionHandler:((Data, URLResponse?, String?, Error?, Int) ->())?) -> Int {
        var uniqueId = -1
        synchronize(callback: { [unowned self] in
            var req = request
            if authorization != nil {
                req.setValue(authorization, forHTTPHeaderField: ZNetworkManager.AuthorizationKey)
            }
            dlog("url: \(req.url!)", flag: ZLog.Flag.debug)
            
            if headerParams != nil {
                for (key, value) in headerParams! {
                    req.addValue(value, forHTTPHeaderField: key)
                }
            }
            
            if params != nil {
                    if req.httpMethod == "GET" {
                        let parameters = params!
                        var urlStr = request.url!.absoluteString
                        urlStr = urlStr + "?" + ZNetworkManager.formattedParamString(params: parameters)
                        req.url = URL(string: urlStr)
                    } else {
                        if isMultipartData {
                            let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
                            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                            var data = Data()
                            
                            for (key, value) in params! {
                                data.append("--\(boundary)\r\n")
                                data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                                data.append("\(value)\r\n")
                            }
                            data.append("\r\n--\(boundary)--")
                            req.httpBody = data
                        }
                        else {
                            let paramData = ZNetworkManager.formattedParamData(params: params!)
                            let paramLength = String(paramData.count)
                            req.setValue(paramLength, forHTTPHeaderField: "Content-Length")
                            if req.httpBody != nil {
                                req.httpBody?.append(paramData)
                            } else {
                                req.httpBody = paramData
                            }
                        }
                    }
            }
            
            uniqueId = self.getNewUniqueId()
            
            let task = ZTask(uniqueId: uniqueId, type: ZTaskType.data, request: req, priority: priority)
            task.requestId = identifier
            task.requestRedirectionHandler = requestRedirectionHandler
            task.completionHandler = completionHandler
            task.delegate = delegate
            
            self.updateTaskBucket(task: task)
            self.taskInfoManager.taskAdded(id: uniqueId, priority: priority, userIdentifier: identifier, metaData: metadata, request: req)
            
            self.run()
        }, async: false)
        return uniqueId
    }
}
