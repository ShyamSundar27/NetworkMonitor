//
//  ZNetworkManager+Download.swift
//  ZNetworkManager
//
//  Created by Rahul T on 30/10/17.
//  Copyright © 2017 Rahul T. All rights reserved.
//

import Foundation

//MARK:- Network Manager Category For Download

extension ZNetworkManager {
    
    /**
     Downloads a url with given http method and params using URLDowloadTask.
     
     - If a download is already active with a given identifier, new download will not start and returns false.
     - Download with a valid identifier will be started, and returns true.
     - Result of this function can be discarded.
     
     # Note
     - Identifier becomes invalid after Pause, Completion, Cancel events.
     
     - **Identifier should be unquie among active download identifiers.**
     
     - Parameter url: Hostname and path of a url to be downloaded.
     
     - Parameter params: parameters to the url.
     
     - Parameter identifier: Unique identifier among active downloads.
     
     - Parameter httpMethod: Get or Post httpMethod.
     
     - Parameter progressDelegate: Delegate to hanldle Completion and Progress.
     
     - Parameter progressPercentageHandler: Handler block to handle periodic progress.
     
     - Parameter progressHandler: Handler block to calculate ther progress percentage by the user
     
     - Parameter completionHandler: Handler block to handle completion of the download.
     */
    @discardableResult
    public func download(url: String, authorization: String? = nil , params: Dictionary<String, Any>?, priority: ZTaskPriority = .medium, metadata: ZNetworkMetaData? = nil, identifier: String?, httpMethod: ZHTTPMethod,
                         progressDelegate:ZTaskProgressDelegate?,
                         progressPercentageHandler: ((_ progress: Float, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite:Int64,  _ identifier: String?, _ taskId: Int) -> ())?,
                         progressHandler:((Data, Double,String?, _ taskId: Int) -> ())?,
                         completionHandler:((_ data: Data, _ response: URLResponse?, _ identifier: String?, _ error: Error?, _ taskId: Int) ->())?) -> Int {
        
        var request: URLRequest = URLRequest(url: URL.init(string:url.encodeURL())!)
        request.httpMethod = httpMethod.rawValue
        
        let taskId = download(request: request, authorization: authorization, params: params,priority: priority, metadata: metadata, identifier: identifier,
                              progressDelegate: progressDelegate,
                              progressPercentageHandler: progressPercentageHandler,
                              progressHandler: progressHandler,
                              completionHandler: completionHandler)
        return taskId
    }
    
    //Download
    @discardableResult
    public func streamingDownload(url: String, authorization: String? = nil , params: Dictionary<String, Any>?, priority: ZTaskPriority = .medium, metadata: ZNetworkMetaData? = nil, identifier: String?, httpMethod: ZHTTPMethod,
                                  progressDelegate:ZTaskProgressDelegate?,
                                  progressPercentageHandler: ((_ progress: Float, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite:Int64,  _ identifier: String?, _ taskId: Int) -> ())?,
                                  progressHandler:((Data, Double, String?, _ taskId: Int) -> ())?,
                                  completionHandler:((_ data: Data, _ response: URLResponse?, _ identifier: String?, _ error: Error?, _ taskId: Int) ->())?) -> Int {
        
        var request: URLRequest = URLRequest(url: URL.init(string:url.encodeURL())!)
        request.httpMethod = httpMethod.rawValue
        
        let taskId = streamingDownload(request: request, authorization: authorization, params: params, metadata: metadata, identifier: identifier, progressDelegate: progressDelegate, progressPercentageHandler: progressPercentageHandler, progressHandler: progressHandler, completionHandler: completionHandler)
        return taskId
    }
    
    @discardableResult
    public func streamingDownload(request: URLRequest, authorization: String? = nil , params: Dictionary<String, Any>?, priority: ZTaskPriority = .medium, metadata: ZNetworkMetaData? = nil, identifier: String?,
                                  progressDelegate:ZTaskProgressDelegate?,
                                  progressPercentageHandler: ((_ progress: Float, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite:Int64,  _ identifier: String?, _ taskId: Int) -> ())?,
                                  progressHandler:((Data, Double, String?, _ taskId: Int) -> ())?,
                                  completionHandler:((_ data: Data, _ response: URLResponse?, _ identifier: String?, _ error: Error?, _ taskId: Int) ->())?) -> Int {
        
        let taskId = download(request: request, authorization: authorization, params: params,priority: priority, metadata: metadata, identifier: identifier, isStreamingDownload: true,
                              progressDelegate: progressDelegate,
                              progressPercentageHandler: progressPercentageHandler,
                              progressHandler: progressHandler,
                              completionHandler: completionHandler)
        return taskId
    }
    
    /**
     Downloads a url with given http method and params using URLDowloadTask.
     
     - If a download is already active with a given identifier, new download will not start and returns false.
     - Download with a valid identifier will be started, and returns true.
     - Result of this function can be discarded.
     
     # Note
     - Identifier becomes invalid after Pause, Completion, Cancel events.
     
     - **Identifier should be unquie among active download identifiers.**
     
     - Parameter request: `URLRequest` to download.
     
     - Parameter params: parameters to the url.
     
     - Parameter identifier: Unique identifier among active downloads.
     
     - Parameter httpMethod: Get or Post httpMethod.
     
     - Parameter progressDelegate: Delegate to hanldle Completion and Progress.
     
     - Parameter progressPercentageHandler: Handler block to handle periodic progress.
     
     - Parameter progressHandler: Handler block to calculate ther progress percentage by the user
     
     - Parameter completionHandler: Handler block to handle completion of the download.
     */
    @discardableResult
    public func download(request: URLRequest, authorization: String? = nil , params: Dictionary<String, Any>?, priority: ZTaskPriority = .medium, metadata: ZNetworkMetaData? = nil, identifier: String?, isStreamingDownload: Bool = false,
                         progressDelegate:ZTaskProgressDelegate?,
                         progressPercentageHandler: ((_ progress: Float, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite:Int64,  _ identifier: String?, _ taskId: Int) -> ())?,
                         progressHandler:((Data, Double ,String?, _ taskId: Int) -> ())?,
                         completionHandler:((_ data: Data, _ response: URLResponse?, _ identifier: String?, _ error: Error?, _ taskId: Int) ->())?) -> Int {
        var urlRequest = request
        
        if authorization != nil {
            urlRequest.setValue(authorization, forHTTPHeaderField: ZNetworkManager.AuthorizationKey)
        }
        dlog("url: \(String(describing: urlRequest.url))", flag: ZLog.Flag.debug)
        if params != nil && !params!.isEmpty {
            if urlRequest.httpMethod == ZHTTPMethod.GET.rawValue {
                let parameters = params!
                var urlStr = request.url!.absoluteString
                urlStr = urlStr + "?" + ZNetworkManager.formattedParamString(params: parameters)
                urlRequest.url = URL(string: urlStr)
            }
            else {
                let paramData = ZNetworkManager.formattedParamData(params: params!)
                let paramLength = String(paramData.count)
                urlRequest.setValue(paramLength, forHTTPHeaderField: "Content-Length")
                if urlRequest.httpBody != nil {
                    urlRequest.httpBody?.append(paramData)
                } else {
                    urlRequest.httpBody = paramData
                }
            }
        }
        
        let downloadType = isStreamingDownload ? ZDownloadType.streamDownload : ZDownloadType.download
        let type = ZTaskType.download(downloadType)
        return startDownload(type: type, request: urlRequest, resumeData: nil, identifier: identifier, priority: priority, metadata: metadata, progressDelegate: progressDelegate, progressPercentageHandler: progressPercentageHandler, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    /**
     Resumes a paused download
     
     - If a download is already active with a given identifier, new download will not start and returns false.
     - Download with a valid identifier will be started, and returns true.
     - Result of this function can be discarded.
     
     # Note
     - Identifier becomes invalid after Pause, Completion, Cancel events.
     
     - **Identifier should be unquie among active download identifiers.**
     
     - Parameter data: resume data in order to continue the download.
     
     - Parameter identifier: Unique identifier among active downloads.
     
     - Parameter progressDelegate: Delegate to hanldle Completion and Progress.
     
     - Parameter progressPercentageHandler: Handler block to handle periodic progress.
     
     - Parameter progressHandler: Handler block to calculate ther progress percentage by the user
     
     - Parameter completionHandler: Handler block to handle completion of the download.
     */
    @discardableResult
    public func resumeDownload(data: Data,
                               priority: ZTaskPriority = .medium, metadata: ZNetworkMetaData? = nil,
                               identifier: String?,
                               progressDelegate: ZTaskProgressDelegate?,
                               progressPercentageHandler: ((_ progress: Float, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite:Int64,  _ identifier: String?, _ taskId: Int) -> ())?,
                               progressHandler:((Data, Double,String?, _ taskId: Int) -> ())?,
                               completionHandler: ((_ data: Data, _ response: URLResponse?, _ identifier: String?, _ error: Error?, _ taskId: Int) ->())?) -> Int {
        return startDownload(type: ZTaskType.download(ZDownloadType.resume), request: nil, resumeData: data,
                             identifier: identifier,
                             priority: priority,
                             metadata: metadata,
                             progressDelegate: progressDelegate,
                             progressPercentageHandler: progressPercentageHandler,
                             progressHandler: progressHandler,
                             completionHandler: completionHandler)
    }
    
    /**
     Pauses an active download and provides resume data through resumeDataHandler.
     
     - If a download is already not active with a given identifier, returns false.
     - Download with a valid identifier will be paused, and returns true.
     - Result of this function can be discarded.
     
     # Note
     - Identifier becomes invalid after Pause, Completion, Cancel events.
     
     - **Identifier should be unquie among active download identifiers.**
     
     - Parameter identifier: Unique identifier among active downloads.
     
     - Parameter resumeDataHandler: Handler to handle resume data.
     */
    @discardableResult
    public func pauseDownload(taskId: Int,
                              resumeDataHandler: @escaping (_ resumeData: Data?, _ taskId: Int) -> ()) -> Bool {
        
        if let task = getTask(taskId: taskId), let downloadTask = task.task as? URLSessionDownloadTask {
            downloadTask.cancel(byProducingResumeData: { [unowned self] (data) in
                resumeDataHandler(data, taskId)
                self.remove(taskId: task.uniqueId)
                self.taskInfoManager.taskEnded(taskId: task.uniqueId, data: data)
            })
            return true
        }
        return false
    }
    
    //MARK:- Helper Methods
    
    private func startDownload(type: ZTaskType, request: URLRequest?, resumeData: Data?, identifier: String?,
                               priority: ZTaskPriority,
                               metadata: ZNetworkMetaData?,
                               progressDelegate: ZTaskProgressDelegate?,
                               progressPercentageHandler: ((_ progress: Float, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite:Int64,  _ identifier: String?, _ taskId: Int) -> ())?,
                               progressHandler:((Data, Double,String?, _ taskId: Int) -> ())?,
                               completionHandler: ((_ data: Data, _ response: URLResponse?, _ identifier: String?, _ error: Error?, _ taskId: Int) ->())?) -> Int {
        var uniqueId = -1
        synchronize(callback: { [unowned self] in
            uniqueId = self.getNewUniqueId()
            dlog("Counter: \(uniqueId)", flag: ZLog.Flag.verbose)
            var task: ZProgressiveTask?
            if let request = request {
                task = ZDownloadTask(uniqueId: uniqueId, type: type, request: request, priority: priority)
            }
            else if let data = resumeData {
                let dTask = ZDownloadTask(uniqueId: uniqueId, type: type, priority: priority)
                dTask.resumeData = data
                task = dTask
            }
            
            if let task = task {
                task.requestId = identifier
                task.completionHandler = completionHandler
                task.progressData = progressHandler
                task.progressPercentHandler = progressPercentageHandler
                task.delegate = progressDelegate
                
                self.updateTaskBucket(task: task)
            }
            
            self.taskInfoManager.taskAdded(id: uniqueId, priority: priority, userIdentifier: identifier, metaData: metadata, request: request)
            
            self.run()
        }, async: false)
        return uniqueId
    }
    
}
