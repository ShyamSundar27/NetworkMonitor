//
//  ZNetworkManager.swift
//  ZNetworkManager
//
//  Created by Rahul T on 10/01/17.
//  Copyright © 2017 Zoho Corporation. All rights reserved.
//

import Foundation
import VTComponents
#if os(iOS)
import MobileCoreServices
#endif

//TODO: TODO 1. Background session 2. Caching if required 3. Error handling 4. Network cancellation


/// Delegate for request callbacks
@objc public protocol ZTaskDelegate:class {
    func downloadCompleted(identifier: String?, data: Data)
    func taskDidReceiveError(forIdentifier identifier: String?, withErrorCode code:Int, message:String?)
}

@objc public protocol ZTaskProgressDelegate:ZTaskDelegate {
    func progressData(identifier: String?, data: Data)
    func progressPercentage(identifier: String?, value: Float)
    func progress(totalBytesWritten: Int64, totoalBytesExpectedToWrite: Int64)
}

@objc public protocol ZTaskResponseDelegate:ZTaskDelegate {
    func didReceiveResponseCode(identifier:Any?,statusCode code:Int)
}

@objc public protocol ZTaskRedirectionDelegate:ZTaskDelegate {
    func didRequestHTTPRedirection(originalRequest: URLRequest, with newRequest: URLRequest)
}

public enum ZHTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}


/// Network Manager Class
@objc public class ZNetworkManager: NSObject {
    
    enum TaskDictKeys:Int {
        case ZTaskId = 1
        case ZTaskDelegate
        case ZTaskData
        case ZTaskProgressData
        case ZTaskProgressPercentage
        case ZTaskCompletionHandler
        case ZTaskProgressHandler
    }
    
    public enum ZTaskPriority: Int {
        case background
        case medium
        case high
    }
    
    enum ZTaskState: Int {
        case idle
        case ready
        case running
        case completed
    }
    
    enum ZTaskType {
        case data
        case upload
        case download(ZDownloadType)
    }
    
    enum ZDownloadType {
        case download
        case streamDownload
        case resume
    }
    
    class ZTask: NSObject {
        var uniqueId: Int
        var requestId: String?
        weak var task: URLSessionTask?
        var request: URLRequest?
        var type: ZTaskType
        var priority: ZTaskPriority
        var state: ZTaskState
        weak var delegate: ZTaskDelegate?
        var data: Data?
        var requestRedirectionHandler: ((_ originalRequest: URLRequest,_ newRequest: URLRequest) -> ())?
        var completionHandler: CompletionHandler?
        
        init(uniqueId: Int, type: ZTaskType, request: URLRequest, priority: ZTaskPriority = .medium, state: ZTaskState = ZTaskState.idle) {
            self.uniqueId = uniqueId
            self.type = type
            self.request = request
            self.state = state
            self.priority = priority
        }
        
        init(uniqueId: Int, type: ZTaskType, priority: ZTaskPriority = .medium, state: ZTaskState = ZTaskState.idle) {
            self.uniqueId = uniqueId
            self.type = type
            self.state = state
            self.priority = priority
        }
        
        override var description: String {
            return "uniqueId: \(uniqueId) state: \(state) type: \(type)"
        }
    }
    
    var uniqueIdCounter: Int = 0
    
    var identifierMapper: [Int: Int] = [Int: Int]()
    
    static let queueIdentifierKey = DispatchSpecificKey<UnsafeMutableRawPointer>()
    static let queueIdentifierValue = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    let queue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.zoho.ZNetworkManager")
        queue.setSpecific(key: queueIdentifierKey, value: queueIdentifierValue)
        return queue
    }()
    
    typealias ProgressDataHandler = (Data, Double, String?, Int) -> ()
    typealias ProgressPercentHandler = (Float, Int64, Int64, String?, Int) -> ()
    typealias CompletionHandler = (Data, URLResponse?, String?, Error?, Int) -> ()
    
    class ZProgressiveTask: ZTask {
        var totalDataCount: Int = 0
        var progressData: ProgressDataHandler?
        var progressPercentHandler: ProgressPercentHandler?
    }
    
    class ZUploadTask: ZProgressiveTask {
        var uploadData: Data
        
        init(uniqueId: Int, type: ZTaskType, request: URLRequest, uploadData: Data, priority: ZTaskPriority = .medium, state: ZTaskState = ZTaskState.idle) {
            self.uploadData = uploadData
            super.init(uniqueId: uniqueId, type: type, request: request, priority: priority, state: state)
        }
    }
    
    class ZDownloadTask: ZProgressiveTask {
        var resumeData: Data?
    }
//    
//    public class ZNetworkResponse {
//        var taskId: Int
//        var data:Data
//        var response: URLResponse?
//        var identifier:String?
//        var error:Error?
//        
//        init(taskId: Int, data: Data = Data()) {
//            self.taskId = taskId
//            self.data = data
//        }
//    }
    
    var taskInfoManager: ZTaskInfoManager = ZTaskInfoManager()
    
    public static let sharedInstance : ZNetworkManager = ZNetworkManager()
    
    lazy var sessionDelegate: ZNetworkManagerSessionDelegate = {
        let delegate = ZNetworkManagerSessionDelegate()
        delegate.manager = self
        return delegate
    }()
    
    //Timeout in seconds
    public var timeoutIntervalForRequest: TimeInterval = 60 //sec
    public var timeoutIntervalForResource: TimeInterval = 600 //10minutes
    
    //Logger
    public var logger: ((_ log: ZLog) -> Void)?
    
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = self.timeoutIntervalForRequest
        config.timeoutIntervalForResource = self.timeoutIntervalForResource
        let session = URLSession(configuration: config, delegate: self.sessionDelegate, delegateQueue: nil)
        return session
    }()
    
    static let AuthorizationKey = "Authorization"
    
    lazy var taskBucket: Dictionary<ZTaskPriority, Dictionary<Int , ZTask>> = {
        var dict = Dictionary<ZTaskPriority, Dictionary<Int , ZTask>>()
        dict.updateValue(Dictionary<Int, ZTask>(), forKey: .high)
        dict.updateValue(Dictionary<Int, ZTask>(), forKey: .medium)
        dict.updateValue(Dictionary<Int, ZTask>(), forKey: .background)
        return dict
    }()
    
    public enum QueueLimit: UInt {
        case `default` = 5
        case infinite = 100000
    }
    
    //change this to increase or decrease the concurrent running tasks
    public var concurrentTaskLimit: UInt = QueueLimit.default.rawValue
    
    var currentRunningTaskCount: Int = 0
    
    //Cancel a task
    public func cancel(taskId: Int) {
        if let task = getTask(taskId: taskId) {
            task.task?.cancel()
            remove(taskId: taskId)
        }
    }
    
    //Cancel all the tasks
    public func cancelAll() {
        for (_, priorityDict) in taskBucket {
            for (taskId, _) in priorityDict {
                cancel(taskId: taskId)
            }
        }
    }
}
