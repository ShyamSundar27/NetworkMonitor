//
//  ZNetworkManager+Setters.swift
//  ZNetworkManager
//
//  Created by Rahul T on 30/10/17.
//  Copyright © 2017 Rahul T. All rights reserved.
//

import Foundation
import VTComponents

extension ZNetworkManager {
    
    //MARK: setter methods
    
    func updateTaskBucket(task: ZTask) {
        synchronize(callback: { [unowned self] in
            dlog("Task: \(task.uniqueId)", flag: ZLog.Flag.verbose)
            self.taskBucket[task.priority]?.updateValue(task, forKey: task.uniqueId)
        }, async: false)
    }
    
    func remove(taskId: Int, success: (() -> ())? = nil) {
        synchronize(callback: { [unowned self] in
            dlog("Task: \(taskId)", flag: ZLog.Flag.verbose)
            if let task = self.getTask(taskId: taskId) {
                if task.state == .running {
                    self.currentRunningTaskCount -= 1
                    self.currentRunningTaskCount = self.currentRunningTaskCount < 0 ? 0 : self.currentRunningTaskCount
                }
            }
            //remove based on hit
            self.taskBucket[.high]?.removeValue(forKey: taskId)
            self.taskBucket[.medium]?.removeValue(forKey: taskId)
            self.taskBucket[.background]?.removeValue(forKey: taskId)
            
            self.removeTaskIdentifier(uniqueId: taskId)
            
            success?()
        }, async: false)
    }
    
    func setTaskData(data: Data, taskId: Int) {
        synchronize(callback: { [unowned self] in
            if let task = self.getTask(taskId: taskId) {
                var mutData = self.taskData(taskId: taskId)
                mutData.append(data)
                task.data = mutData
                self.updateTaskBucket(task: task)
            }
        }, async: false)
    }
    
    func setTaskTotalDataCount(count: Int, taskId: Int) {
        synchronize(callback: { [unowned self] in
            if let task = self.getTask(taskId: taskId) as? ZProgressiveTask {
                task.totalDataCount = count
                self.updateTaskBucket(task: task)
            }
        }, async: false)
    }
    
    func setSessionTaskIdentifier(_ identifier: Int, uniqueId: Int) {
        synchronize(callback: { [unowned self] in
            dlog("identifier: \(identifier) uniqueId: \(uniqueId)", flag: ZLog.Flag.verbose)
            self.identifierMapper[uniqueId] = identifier
        }, async: false)
    }
    
    func removeTaskIdentifier(uniqueId: Int) {
        synchronize(callback: { [unowned self] in
            dlog("uniqueId: \(uniqueId)", flag: ZLog.Flag.verbose)
            self.identifierMapper.removeValue(forKey: uniqueId)
        }, async: false)
    }
}
