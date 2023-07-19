//
//  ZTaskInfo.swift
//  ZNetworkManager
//
//  Created by Abdul Rahuman K on 18/07/19.
//

import Foundation
import VTComponents

public class ZNetworkMetaData {
    public var groupId: String?
    public var groupActionName: String?
    public var isUserInitiated: Bool?
    
    public var apiName: String?
    public var moduleName: String?
    
    public init() {}
}

public class ZTaskInfo {
    
    public enum Priority: String {
        case low
        case medium
        case high
    }
    
    public var id: Int
    public var task: URLSessionTask?
    public var userIdentifier: String?
    public var priority: Priority = .medium
    public var data: Data?
    public var startTime: Date?
    public var endTime: Date?
    public var responseData: Data?
    public var metaData: ZNetworkMetaData?
    public var request: URLRequest?
    
    public init(id: Int) {
        self.id = id
    }
}

public protocol ZTaskInfoObserver {
    func added(task: ZTaskInfo)
    func updated(task: ZTaskInfo)
    func ended(task: ZTaskInfo)
}

public class ZTaskInfoManager {
    
    private var currentTasks: [Int: ZTaskInfo] = [:]
    private var queue = DispatchQueue(label: "SyncQueue", qos: DispatchQoS.background, attributes: [.concurrent])
    
    public func taskAdded(id: Int, priority: ZNetworkManager.ZTaskPriority = .medium, userIdentifier: String? = nil, metaData: ZNetworkMetaData? = nil, request: URLRequest? = nil) {
        let taskInfo = ZTaskInfo(id: id)
        taskInfo.priority = convert(priority: priority)
        taskInfo.metaData = metaData
        taskInfo.request = request
        addTask(task: taskInfo)
        ZNotificationCenter.shared.notify(ZTaskInfoObserver.self) { (observer) in
            observer.added(task: taskInfo)
        }
    }
    
    public func taskStarted(taskId: Int, task: URLSessionTask) {
        let startTime = Date()
        getTask(id: taskId) { (taskInfo) in
            if let taskInfo = taskInfo  {
                taskInfo.task = task
                taskInfo.startTime = startTime
                ZNotificationCenter.shared.notify(ZTaskInfoObserver.self) { (observer) in
                    observer.updated(task: taskInfo)
                }
            }
        }
    }
    
    public func taskStatusUpdate(taskId: Int, data: Data?) {
        getTask(id: taskId) { (taskInfo) in
            if let taskInfo = taskInfo {
                if let data = data {
                    if taskInfo.responseData == nil {
                        taskInfo.responseData = data
                    }
                    else {
                        taskInfo.responseData = data
                    }
                }
                ZNotificationCenter.shared.notify(ZTaskInfoObserver.self) { (observer) in
                    observer.updated(task: taskInfo)
                }
            }
        }
    }
    
    public func taskEnded(taskId: Int, data: Data?) {
        let endTime = Date()
        if let taskInfo = removeTask(id: taskId) {
            if let data = data {
                if taskInfo.responseData == nil {
                    taskInfo.responseData = data
                }
                else {
                    taskInfo.responseData = data
                }
            }
            taskInfo.endTime = endTime
            ZNotificationCenter.shared.notify(ZTaskInfoObserver.self) { (observer) in
                observer.ended(task: taskInfo)
            }
        }
    }
    
    private func getTask(id: Int, callback: @escaping (ZTaskInfo?) -> Void) {
        var element: ZTaskInfo?
        queue.async { [weak self] in
            element = self?.currentTasks[id]
            callback(element)
        }
    }
    
    private func removeTask(id: Int) -> ZTaskInfo? {
        var element: ZTaskInfo?
        queue.sync { [weak self] in
            element = self?.currentTasks.removeValue(forKey: id)
        }
        return element
    }
    
    private func addTask(task: ZTaskInfo) {
        queue.async(flags: .barrier) { [weak self] in
            self?.currentTasks[task.id] = task
        }
    }
    
    private func convert(priority: ZNetworkManager.ZTaskPriority) -> ZTaskInfo.Priority {
        switch priority {
        case .background:
            return .low
        case .medium:
            return .medium
        case .high:
            return .high
        }
    }
    
}
