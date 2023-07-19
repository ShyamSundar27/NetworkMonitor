//
//  ZNetworkManager+Upload.swift
//  ZNetworkManager
//
//  Created by Rahul T on 26/10/17.
//  Copyright © 2017 Zoho Corporation. All rights reserved.
//

import Foundation

#if !os(macOS)
import MobileCoreServices
#endif


public struct ZFileUploadInfo {
    
    public let fileParamName: String
    public let fileName: String
    public let source: Source
    
    public init(fileParamName: String, fileName: String, source: Source) {
        self.fileParamName = fileParamName
        self.fileName = fileName
        self.source = source
    }
    
    public enum Source {
        case path(URL)
        case data(Data)
    }
}


// MARK: - Network Manager Category for upload

extension ZNetworkManager
{
    
    /// Call this instance method to upload file using Data
    ///
    /// - Parameters:
    ///   - method: POST/GET
    ///   - url: API request URL
    ///   - fileName: name of the file
    ///   - fileData: upload file as Data
    ///   - fileParamName: file param for HTTP body
    ///   - params: API params as Dictionary
    ///   - delegate: delegate for callbacks
    ///   - identifier: identifier for the request to identify the caller
    ///   - progressDataHandler: progress of data returned as completion block
    ///   - progressPercentageHandler: progress percentage returned as completion block
    ///   - completionHandler: completion returned as completion block
    @discardableResult
    public func sendUploadRequestURL(method: ZHTTPMethod, url: String, authorization: String? = nil, priority : ZTaskPriority = .medium, fileInfos: [ZFileUploadInfo], params: Dictionary<String, Any>?, delegate:ZTaskDelegate?, metadata: ZNetworkMetaData? = nil, identifier: String?, progressDataHandler:((Data, Double ,String?,Int) ->())?, progressPercentageHandler: ((Float, Int64, Int64, String?, Int) -> ())?, completionHandler: ((Data, URLResponse?, String?, Error?, Int) ->())?) -> Int {
        
        var request = URLRequest(url: URL(string: url.encodeURL())!)
        request.httpMethod = method.rawValue
        if authorization != nil {
            request.setValue(authorization!, forHTTPHeaderField: ZNetworkManager.AuthorizationKey)
        }
        
        return sendUploadRequest(request, priority: priority, fileInfos: fileInfos, params: params, delegate: delegate, metadata: metadata, identifier: identifier, progressDataHandler: progressDataHandler, progressPercentageHandler: progressPercentageHandler, completionHandler: completionHandler)
    }
    
    @discardableResult
    public func sendUploadRequest(_ request: URLRequest, authorization: String? = nil, priority: ZTaskPriority = .medium, fileInfos: [ZFileUploadInfo], params: Dictionary<String, Any>?, delegate: ZTaskDelegate?, metadata: ZNetworkMetaData? = nil, identifier: String?, progressDataHandler: ((Data, Double, String?, Int) ->())?, progressPercentageHandler: ((Float, Int64, Int64, String?, Int) -> ())?, completionHandler: ((Data, URLResponse?, String?, Error?, Int) ->())?) -> Int {
        
        var uniqueId = -1
        synchronize(callback: { [unowned self] in
            let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
            
            var data = Data()
            data.append("\r\n--\(boundary)\r\n")
            if params != nil {
                for (key, value) in params! {
                    data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                    data.append("\(value)\r\n")
                    data.append("--\(boundary)\r\n")
                }
            }
            for (index, fileInfo) in fileInfos.enumerated() {
                let fileName = fileInfo.fileName
                let mimeType = self.mimeTypeForExtension(pathExtension: (fileName as NSString).pathExtension)
                var fileData: Data?
                switch fileInfo.source {
                case .path(let path):
                    var isDirectory: ObjCBool = ObjCBool.init(false)
                    if FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory) {
                        guard !isDirectory.boolValue else {
                            let error = NSError.init(domain: "Permission denied", code: 12, userInfo: nil)
                            completionHandler?(Data(), nil, identifier, error, -1)
                            continue
                        }
                        fileData = try? Data(contentsOf: path)
                        guard fileData != nil else {
                            continue
                        }
                    }
                    
                    
                case .data(let data):
                    fileData = data
                }
                
                data.append("Content-Disposition: form-data; name=\"\(fileInfo.fileParamName)\"; filename=\"\(fileName)\"\r\n")
                data.append("Content-Type: \(mimeType)\r\n\r\n")
                if let fileData = fileData {
                    data.append(fileData)
                }
                if index == fileInfos.count - 1 {
                    data.append("\r\n--\(boundary)--")
                } else {
                    data.append("\r\n--\(boundary)\r\n")
                }
            }
            
            var req = request
            if authorization != nil {
                req.setValue(authorization!, forHTTPHeaderField: "Authorization")
            }
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            uniqueId = self.getNewUniqueId()
            
            let task = ZUploadTask(uniqueId: uniqueId, type: ZTaskType.upload, request: req, uploadData: data, priority: priority)
            task.requestId = identifier
            task.completionHandler = completionHandler
            task.progressData = progressDataHandler
            task.progressPercentHandler = progressPercentageHandler
            task.delegate = delegate
            
            self.updateTaskBucket(task: task)
            self.taskInfoManager.taskAdded(id: uniqueId, priority: priority, userIdentifier: identifier, metaData: metadata, request: req)
            
            self.run()
        }, async: false)
        return uniqueId
    }
    
    private func mimeTypeForExtension(pathExtension: String) -> String
    {
        let uti:Array = (UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeUnretainedValue())! as Array
        let mimeType:CFString? = (UTTypeCopyPreferredTagWithClass(uti[0] as! CFString, kUTTagClassMIMEType))?.takeUnretainedValue()
        if(mimeType != nil)
        {
            let mimeTypeNsType: NSString = mimeType! as NSString
            return mimeTypeNsType as String
        }
        return "application/octet-stream"
    }
    
    public static func formattedParamString(params: Dictionary<String,Any>)-> String
    {
        var paramString = ""
        for (key,value) in params {
            paramString += getKeyString(from: key, in: paramString)
            paramString += getValueString(from: value)
        }
        return paramString
    }
    
    private static func getKeyString(from key: String, in paramString: String) -> String {
        if(paramString.isEmpty) {
            return key + "="
        }
        return "&" + key + "="
    }
    
    private static func getValueString(from value: Any) -> String {
        if value is Dictionary<String, Any> && JSONSerialization.isValidJSONObject(value) {
            if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: []) {
                let jsonString = String(data: jsonData, encoding: .utf8)!
                return jsonString.encodeValue()
            }
        }
        return "\(value)".encodeValue()
    }
}

extension Data {
    mutating func append(_ string: String) {
        self.append(string.data(using: .utf8)!)
    }
}
