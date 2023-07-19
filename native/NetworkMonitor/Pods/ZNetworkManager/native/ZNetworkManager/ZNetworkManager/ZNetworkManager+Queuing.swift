//
//  ZNetworkManager+Queuing.swift
//  ZNetworkManager
//
//  Created by Rahul T on 31/10/17.
//  Copyright © 2017 Rahul T. All rights reserved.
//

import Foundation

extension ZNetworkManager {
    
    func run() {
        synchronize(callback: {
            let tasks = self.getRunnableTasks()
            dlog("Tasks: \(tasks)", flag: ZLog.Flag.verbose)
            for task in tasks {
                dlog("started running \(task.uniqueId) state: \(task.state)", flag: ZLog.Flag.debug)
                self.markAsReady(task: task)
                self.runTask(task: task)
                if let sessionTask = task.task {
                    self.taskInfoManager.taskStarted(taskId: task.uniqueId, task: sessionTask)
                }
            }
        }, async: false)
    }
    
    func getRunnableTasks() -> [ZTask] {
        var tasks = [ZTask]()
        synchronize(callback: { [unowned self] in
            if let taskDict = self.getTasks(priority: .high) {
                for (_,task) in taskDict {
                    if self.canRun(priority: ZNetworkManager.ZTaskPriority.high) && task.state == .idle {
                        dlog("task to run \(task.uniqueId) -- \(task.state)", flag: ZLog.Flag.debug)
                        tasks.append(task)
                        //currentRunningTaskCount.value += 1
                    }
                }
            }
            if let taskDict = self.getTasks(priority: .medium) {
                for (_,task) in taskDict {
                    if self.canRun(priority: ZNetworkManager.ZTaskPriority.medium) && task.state == .idle {
                        dlog("task to run \(task.uniqueId) -- \(task.state)", flag: ZLog.Flag.debug)
                        tasks.append(task)
                        self.currentRunningTaskCount += 1
                    }
                }
            }
            if let taskDict = self.getTasks(priority: .background) {
                for (_,task) in taskDict {
                    if self.canRun(priority: ZNetworkManager.ZTaskPriority.background) && task.state == .idle {
                        dlog("task to run \(task.uniqueId) -- \(task.state)", flag: ZLog.Flag.debug)
                        tasks.append(task)
                        self.currentRunningTaskCount += 1
                    }
                }
            }
        }, async: false)
        return tasks
    }
    
    func getTask(taskId: Int) -> ZTask? {
        //get based on hit
        var task: ZTask?
        synchronize(callback: { [unowned self] in
            var taskDict = self.getTasks(priority: .high)
            if let taskInDict = taskDict?[taskId] {
                task = taskInDict
            }
            else if let taskInDict = self.getTasks(priority: .medium)?[taskId] {
                task = taskInDict
            }
            else if let taskInDict = self.getTasks(priority: .background)?[taskId] {
                task = taskInDict
            }
        }, async: false)
        return task
    }
    
    func getProgressTask(taskId: Int) -> ZProgressiveTask? {
        return getTask(taskId: taskId) as? ZProgressiveTask
    }
    
    func getTasks(priority: ZTaskPriority) -> [Int: ZTask]? {
        var tasks: [Int: ZTask]?
        synchronize(callback: { [unowned self] in
            tasks = self.taskBucket[priority]
        }, async: false)
        return tasks
    }
    
    func markAsReady(task: ZTask) {
        synchronize(callback: { [unowned self] in
            task.state = .ready
            self.updateTaskBucket(task: task)
        }, async: false)
    }
    
    func markTaskAsRunning(task: ZTask) {
        synchronize(callback: { [unowned self] in
            task.state = .running
            self.updateTaskBucket(task: task)
        }, async: false)
    }
    
    func canRun(priority: ZTaskPriority) -> Bool {
        var status = false
        synchronize(callback: { [unowned self] in
            if self.concurrentTaskLimit == QueueLimit.infinite.rawValue {
                status = true
            }
            else {
                status = self.currentRunningTaskCount < self.getLimit(for: priority)
            }
        }, async: false)
        return status
    }
    
    private func getLimit(for priority: ZTaskPriority) -> UInt {
        switch priority {
        case .high:
            return QueueLimit.infinite.rawValue
        case .medium:
            return concurrentTaskLimit
        case.background:
            let limitOffSet = UInt(ceil(Double(concurrentTaskLimit) * 0.25))
            return concurrentTaskLimit - limitOffSet
        }
    }
}
