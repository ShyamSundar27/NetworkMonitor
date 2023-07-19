//
//  ZNetworkManager+Getters.swift
//  ZNetworkManager
//
//  Created by Rahul T on 30/10/17.
//  Copyright © 2017 Rahul T. All rights reserved.
//

import Foundation
import VTComponents

extension ZNetworkManager {
    
    func getSession(priority: ZTaskPriority) -> URLSession {
        return session
    }
    
    func getDataTask(priority: ZTaskPriority, request: URLRequest) -> URLSessionDataTask {
        let task = getSession(priority: priority).dataTask(with: request)
        return task
    }
    
    func getDownloadTask(priority: ZTaskPriority, request: URLRequest) -> URLSessionDownloadTask {
        let task = getSession(priority: priority).downloadTask(with: request)
        return task
    }
    
    func getDownloadTask(priority: ZTaskPriority, resumeData: Data) -> URLSessionDownloadTask {
        let task = getSession(priority: priority).downloadTask(withResumeData: resumeData)
        return task
    }
    
    func getUploadTask(priority: ZTaskPriority, request: URLRequest, data: Data) -> URLSessionUploadTask {
        let task = getSession(priority: priority).uploadTask(with: request, from: data)
        return task
    }
    
    func taskData(taskId: Int) -> Data {
        let data = getTask(taskId: taskId)?.data ?? Data()
        return data
    }
    
    func taskDelegate(taskId: Int) -> ZTaskDelegate? {
        return getTask(taskId: taskId)?.delegate
    }
    
    func taskProgressDelegate(taskId: Int) -> ZTaskProgressDelegate? {
        return getTask(taskId: taskId)?.delegate as? ZTaskProgressDelegate
    }
    
    func taskResponseDelegate(taskId: Int) -> ZTaskResponseDelegate? {
        return getTask(taskId: taskId)?.delegate as? ZTaskResponseDelegate
    }
    
    func taskRedirectionDelegate(taskId: Int) -> ZTaskRedirectionDelegate? { //Added by Narayanan U
        return getTask(taskId: taskId)?.delegate as? ZTaskRedirectionDelegate
    }
    
    func taskCompletionHandler(taskId: Int) -> CompletionHandler? {
        return getTask(taskId: taskId)?.completionHandler
    }
    
    func taskRequestRedirectionHandler(taskId: Int) -> ((_ originalRequest: URLRequest,_ newRequest: URLRequest) -> ())? {
        return getTask(taskId: taskId)?.requestRedirectionHandler
    }
    
    func taskTotalDataCount(taskId: Int) -> Int? {
        return getProgressTask(taskId: taskId)?.totalDataCount
    }
    
    func taskProgressDataHandler(taskId: Int) -> ProgressDataHandler? {
        return getProgressTask(taskId: taskId)?.progressData
    }
    
    func taskProgressPercentageHandler(taskId: Int) -> ProgressPercentHandler? {
        return getProgressTask(taskId: taskId)?.progressPercentHandler
    }
    
    func getUniqueId(taskIdenfitier: Int) -> Int? {
        var uniqueId: Int?
        synchronize(callback: { [unowned self] in
            for (key,value) in self.identifierMapper {
                if value == taskIdenfitier {
                    uniqueId = key
                }
            }
        }, async: false)
        return uniqueId
    }
    
    func taskId(taskId: Int) -> String? {
        return getTask(taskId: taskId)?.requestId
    }
    
    func getNewUniqueId() -> Int {
        synchronize(callback: {
            self.uniqueIdCounter += 1
        }, async: false)
        return uniqueIdCounter
    }
}
