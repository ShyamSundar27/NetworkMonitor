//
//  Synchronization.swift
//  ZNetworkManager
//
//  Created by Rahul T on 12/01/17.
//  Copyright © 2017 Zoho Corporation. All rights reserved.
//

import Foundation

public typealias SimpleClosure = () -> Void

public func synchronized(_ object: Any, _ closure: SimpleClosure) {
    objc_sync_enter(object)
    closure()
    objc_sync_exit(object)
}

@discardableResult
public func delayOnMainThread(_ delay: TimeInterval, handler: @escaping SimpleClosure) ->  DispatchWorkItem {
    let dispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(Int(delay))
    let task = DispatchWorkItem(block: handler)
    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: task)
    return task
}

@discardableResult
public func delay(_ delay: TimeInterval, queue: DispatchQueue = DispatchQueue.global(), handler: @escaping SimpleClosure) ->  DispatchWorkItem {
    let dispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(Int(delay))
    let task = DispatchWorkItem(block: handler)
    queue.asyncAfter(deadline: dispatchTime, execute: task)
    return task
}
