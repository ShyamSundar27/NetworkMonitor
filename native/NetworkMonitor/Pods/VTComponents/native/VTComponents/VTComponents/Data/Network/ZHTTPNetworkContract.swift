//
//  ZHTTPNetworkContract.swift
//  VTComponents-Lite
//
//  Created by Rahul T on 06/08/19.
//

import Foundation

public class ZHTTP {
    
    public enum Priority: Int {
        case background
        case medium
        case high
    }
    
    public enum Method: String {
        case GET
        case POST
        case PUT
        case PATCH
        case DELETE
    }
    
    public class ZURL: CustomStringConvertible {
        
        public var url: String
        public var method: Method
        
        public init(method: Method, url: String) {
            self.method = method
            self.url = url
        }
        
        public var description: String {
            return "url: \(url) method: \(method)"
        }
    }
    
    public class ZohoAuth {
        
        public var zuid: String
        
        public init(zuid: String) {
            self.zuid = zuid
        }
    }
    
    public enum Authentication {
        case zoho(ZohoAuth)
        case none
        
        public func isZoho() -> Bool {
            if case .zoho(_) = self {
                return true
            }
            return false
        }
        
        public func getZoho() -> ZohoAuth? {
            if case let .zoho(zoho) = self {
                return zoho
            }
            return nil
        }
    }
    
    public enum HTTPRequest {
        case url(ZHTTP.ZURL)
        case request(URLRequest)
        
        public func getURL() -> ZHTTP.ZURL? {
            if case let .url(url) = self {
                return url
            }
            return nil
        }
        
        public func getRequest() -> URLRequest? {
            if case let .request(request) = self {
                return request
            }
            return nil
        }
    }
    
    public class Request: CustomStringConvertible {
        
        public var request: HTTPRequest
        public var authentication: Authentication
        public var identifier: String?
        public var headerParams: Dictionary<String, String>?
        public var params: Dictionary<String, Any>?
        public var isMultiPartData: Bool = false
        public var priority: Priority = Priority.medium
        
        public init(request: HTTPRequest, authentication: Authentication) {
            self.request = request
            self.authentication = authentication
        }
        
        public var description: String {
            let requestDesc = request.getURL()?.description ?? (request.getRequest()?.description ?? "No request")
            return "identifier: \(String(describing: identifier)) request: \(requestDesc)"
        }
    }
    
    public class Response: CustomStringConvertible {
        
        public var taskId: Int
        public var response: URLResponse?
        public var identifier: String?
        public var status: Status
        
        public init(taskId: Int, status: Status) {
            self.taskId = taskId
            self.status = status
        }
        
        public var description: String {
            return "identifier: \(String(describing: identifier)) error: \(String(describing: status))"
        }
    }
    
    public enum Status {
        case success(Data)
        case authenticationFailure(AuthenticationError)
        case error(Error)
    }
    
    public enum AuthenticationError {
        case sessionExpired
        case invalidToken
        case tokenNotFound
        case unknownError
    }
    
    public class FileUploadInfo {
        
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
    
    public typealias TaskInfoHandler = (_ taskId: Int) -> ()
    public typealias CompletionHandler = (ZHTTP.Response) -> ()
}

public protocol ZHTTPNetworkContract {
    
    func send(request: ZHTTP.Request, requestRedirectionHandler: ((_ originalRequest: URLRequest,_ newRequest: URLRequest) -> ())?, taskInfoHandler: ZHTTP.TaskInfoHandler?, completionHandler: @escaping ZHTTP.CompletionHandler)
    
    func download(request: ZHTTP.Request, requestDidStartHandler: ((Int) -> ())?, progressPercentageHandler: ((_ progress: Float, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite:Int64, _ identifier: String?, _ taskId: Int) -> ())?, progressHandler: ((Data, Double, String?, _ taskId: Int) -> ())?, taskInfoHandler: ZHTTP.TaskInfoHandler?, completionHandler: @escaping ZHTTP.CompletionHandler)
    
    func resumeDownload(request: ZHTTP.Request, data: Data, progressPercentageHandler: ((_ progress: Float, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64,  _ identifier: String?, _ taskId: Int) -> ())?, progressHandler: ((Data, Double, String?, _ taskId: Int) -> ())?, taskInfoHandler: ZHTTP.TaskInfoHandler?, completionHandler: @escaping ZHTTP.CompletionHandler)
    
    func upload(request: ZHTTP.Request, fileInfos: [ZHTTP.FileUploadInfo], progressDataHandler: ((Data, Double, String?, Int) ->())?, progressPercentageHandler: ((Float, Int64, Int64, String?, Int) -> ())?, taskInfoHandler: ZHTTP.TaskInfoHandler?, completionHandler: @escaping ZHTTP.CompletionHandler)
    
    func cancel(taskId: Int)

    //MARK:- Utils
    
    func formattedParamString(params: Dictionary<String,Any>) -> String
}
