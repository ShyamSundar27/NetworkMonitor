//
//  ZNetworkManager+SessionDelegate.swift
//  ZNetworkManager
//
//  Created by Rahul T on 31/10/17.
//  Copyright © 2017 Rahul T. All rights reserved.
//

import Foundation

extension ZNetworkManager {
    
    class ZNetworkManagerSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
        
        weak var manager: ZNetworkManager?
        
        //URLSessionDelegate
        
        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            if error != nil {
                dlog("error: \(error!)", flag: ZLog.Flag.error)
            }
        }
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            dlog("authentication challenge \(challenge)", flag: ZLog.Flag.verbose)
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
        
        
        //URLSessionTaskDelegate
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
           
            guard manager != nil else {
                dlog("manager is nil", flag: ZLog.Flag.error)
                return
            }
            
            guard let uniqueId = manager?.getUniqueId(taskIdenfitier: task.taskIdentifier) else {
                dlog("TaskId not found for identifier: \(task.taskIdentifier)", flag: ZLog.Flag.error)
                return
            }
            
            manager?.taskInfoManager.taskEnded(taskId: uniqueId, data: manager?.taskData(taskId: uniqueId))
            
            if error != nil
            {
                manager?.taskDelegate(taskId: uniqueId)?.taskDidReceiveError(forIdentifier: manager?.taskId(taskId: uniqueId), withErrorCode: (error! as NSError).code, message: error?.localizedDescription)
            }
            
            manager?.taskDelegate(taskId: uniqueId)?.downloadCompleted(identifier: manager?.taskId(taskId: uniqueId), data: manager!.taskData(taskId: uniqueId))
            
            manager?.taskCompletionHandler(taskId: uniqueId)?(manager!.taskData(taskId: uniqueId), task.response, manager?.taskId(taskId: uniqueId), error, uniqueId)
            manager?.remove(taskId: uniqueId, success: { [weak self] in
                self?.manager?.run()
            })
            
            
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
            guard manager != nil else {
                dlog("manager is nil", flag: ZLog.Flag.error)
                return
            }
            
            guard let uniqueId = manager?.getUniqueId(taskIdenfitier: task.taskIdentifier) else {
                dlog("TaskId not found for identifier: \(task.taskIdentifier)", flag: ZLog.Flag.error)
                return
            }
            
            let progress:Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
            manager?.taskProgressDelegate(taskId: uniqueId)?.progressPercentage(identifier: manager?.taskId(taskId: uniqueId), value: progress)
            manager?.taskProgressDelegate(taskId: uniqueId)?.progress(totalBytesWritten: totalBytesSent, totoalBytesExpectedToWrite: totalBytesExpectedToSend)
            manager?.taskProgressPercentageHandler(taskId: uniqueId)?(progress,totalBytesSent,totalBytesExpectedToSend,manager?.taskId(taskId: uniqueId), uniqueId)
            
            manager?.taskInfoManager.taskStatusUpdate(taskId: uniqueId, data: manager?.taskData(taskId: uniqueId))
        }
        
        //Added by Narayanan U
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            
            guard manager != nil else {
                dlog("manager is nil", flag: ZLog.Flag.error)
                return
            }
            
            guard let uniqueId = manager?.getUniqueId(taskIdenfitier: task.taskIdentifier) else {
                dlog("TaskId not found for identifier: \(task.taskIdentifier)", flag: ZLog.Flag.error)
                return
            }
            
            if let req = task.originalRequest {
                manager?.taskRedirectionDelegate(taskId: uniqueId)?.didRequestHTTPRedirection(originalRequest: req, with: request)
                manager?.taskRequestRedirectionHandler(taskId: uniqueId)?(req, request)
            }
        }
        
        @available(tvOS 10.0, *)
        @available(watchOSApplicationExtension 3.0, *)
        @available(iOS 10.0, *)
        @available(OSX 10.12, *)
        func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics){
            
            dlog("Download Ended - Time: \(metrics.taskInterval.duration)  URL: \(task.currentRequest?.url?.absoluteString ?? "no url")", flag: ZLog.Flag.debug)
        }
        
        //URLSessionDataDelegate
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            
            guard manager != nil else {
                dlog("manager is nil", flag: ZLog.Flag.error)
                return
            }
            
            guard let uniqueId = manager?.getUniqueId(taskIdenfitier: dataTask.taskIdentifier) else {
                dlog("TaskId not found for identifier: \(dataTask.taskIdentifier)", flag: ZLog.Flag.error)
                return
            }
            
            manager?.setTaskData(data: data, taskId: uniqueId)
            manager?.taskProgressDelegate(taskId: uniqueId)?.progressData(identifier: manager?.taskId(taskId: uniqueId), data: data)
            var currentProgress: Double = 0
            
            if let data = manager?.taskData(taskId: uniqueId), let count = manager?.taskTotalDataCount(taskId: uniqueId) {
                currentProgress = (Double(data.count) / Double(count)) * 100
            }
            manager?.taskProgressDataHandler(taskId: uniqueId)?(manager!.taskData(taskId: uniqueId), currentProgress, manager?.taskId(taskId: uniqueId), uniqueId)
            
            manager?.taskInfoManager.taskStatusUpdate(taskId: uniqueId, data: manager?.taskData(taskId: uniqueId))
            
        }
        
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
        {
            guard let uniqueId = manager?.getUniqueId(taskIdenfitier: dataTask.taskIdentifier) else {
                dlog("TaskId not found for identifier: \(dataTask.taskIdentifier)", flag: ZLog.Flag.error)
                return
            }
            
            if response.isKind(of: HTTPURLResponse.self)
            {
                let httpResponse:HTTPURLResponse? = response as? HTTPURLResponse
                let code:Int? = httpResponse?.statusCode
                manager?.taskResponseDelegate(taskId: uniqueId)?.didReceiveResponseCode(identifier: manager?.taskId(taskId: uniqueId), statusCode: code!)
                manager?.setTaskTotalDataCount(count: Int(response.expectedContentLength), taskId: uniqueId)
            }
            completionHandler(.allow)
        }
        
        //MARK:- URL Session Download Task Delegate
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                        didFinishDownloadingTo location: URL) {
            
            guard let uniqueId = manager?.getUniqueId(taskIdenfitier: downloadTask.taskIdentifier) else {
                dlog("TaskId not found for identifier: \(downloadTask.taskIdentifier)", flag: ZLog.Flag.error)
                return
            }
            
            if let data = try? Data(contentsOf: location) {
                manager?.setTaskData(data: data, taskId: uniqueId)
            }
            
            manager?.taskInfoManager.taskEnded(taskId: uniqueId, data: manager?.taskData(taskId: uniqueId))
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                        didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                        totalBytesExpectedToWrite: Int64) {
            
            guard let uniqueId = manager?.getUniqueId(taskIdenfitier: downloadTask.taskIdentifier) else {
                dlog("TaskId not found for identifier: \(downloadTask.taskIdentifier)", flag: ZLog.Flag.error)
                return
            }
            
            let progress = (Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)) * 100
            let identifier = manager?.taskId(taskId: uniqueId)
            let percentageHandler = manager?.taskProgressPercentageHandler(taskId: uniqueId)
            percentageHandler?(progress, totalBytesWritten, totalBytesExpectedToWrite, identifier, uniqueId)
            manager?.taskInfoManager.taskStatusUpdate(taskId: uniqueId, data: manager?.taskData(taskId: uniqueId))
        }
    }
}
