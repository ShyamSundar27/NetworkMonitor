//
//  ZNetworkManager+Helper.swift
//  ZNetworkManager
//
//  Created by Rahul T on 27/08/19.
//  Copyright © 2019 Rahul T. All rights reserved.
//

import Foundation

extension ZNetworkManager {
    
    func runTask(task: ZTask) {
        var sessionTask: URLSessionTask?
        switch task.type {
        case .data:
            if let request = task.request {
                sessionTask = getDataTask(priority: task.priority, request: request)
            }
            else {
                dlog("Request not found :\(task)", flag: ZLog.Flag.error)
            }
        case .upload:
            if let uploadTask = task as? ZUploadTask, let request = uploadTask.request {
                sessionTask = getUploadTask(priority: task.priority, request: request, data: uploadTask.uploadData)
            }
            else {
                dlog("Request not found :\(task)", flag: ZLog.Flag.error)
            }
        case .download(let downloadType):
            switch downloadType {
            case .download:
                if let request = task.request {
                    sessionTask = getDownloadTask(priority: task.priority, request: request)
                }
            case .streamDownload:
                if let request = task.request {
                    sessionTask = getDataTask(priority: task.priority, request: request)
                }
                else {
                    dlog("Request not found :\(task)", flag: ZLog.Flag.error)
                }
            case .resume:
                if let downloadTask = task as? ZDownloadTask, let resumeData = downloadTask.resumeData {
                    sessionTask = getDownloadTask(priority: task.priority, resumeData: resumeData)
                }
                else {
                    dlog("Couldn't convert :\(task)", flag: ZLog.Flag.error)
                }
            }
        }
        if let sessionTask = sessionTask {
            setSessionTaskIdentifier(sessionTask.taskIdentifier, uniqueId: task.uniqueId)
            sessionTask.resume()
            task.task = sessionTask
        }
        markTaskAsRunning(task: task)
    }
    
    func synchronize(callback: @escaping () -> (), async: Bool) {
        if DispatchQueue.getSpecific(key: ZNetworkManager.queueIdentifierKey) == ZNetworkManager.queueIdentifierValue {
            callback()
        }
        else {
            if async {
                queue.async {
                    callback()
                }
            }
            else {
                queue.sync {
                    callback()
                }
            }
        }
    }
}
