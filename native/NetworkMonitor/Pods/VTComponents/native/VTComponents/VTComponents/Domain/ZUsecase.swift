//
//  ZUsecase.swift
//  ZohoMail
//
//  Created by Rahul T on 24/07/17.
//  Copyright © 2017 Zoho Corporation. All rights reserved.
//

import Foundation

//Request to have without zuid
open class Request {
    public var qos: DispatchQoS.QoSClass = .utility //Quality of Service

    public init() { }
}

open class Response {

    enum Status {
        case success
        case networkUnavailable
        case timeout
        case authenticationFailure
        case dataNotFound
        case parsingFailed
        case unknownError
    }

    var status: Status

    public init() {
        self.status = .success
    }
}

public enum ZRequestType: Int {
    case database
    case network
    case both
}

open class ZRequest: Request {
    public var zuid: String

    public init(zuid: String) {
        self.zuid = zuid
    }
}

open class ZResponse: Response {

    public override init() { }
}

public enum ZErrorType: Error {
    case networkUnavailable
    case timeout
    case authenticationFailure
    case dataNotFound
    case parsingFailed
    case unknownError
    case serverFailure
    case networkIPLock
}

open class ZError {
    public var type: ZErrorType?

    public init(type: ZErrorType? = nil) {
        self.type = type
    }
}

open class ZActivityMetaData {
    //metadata for activity tracker
    public var groupId: String?
    public var groupActionName: String?
    public var moduleName: String?
    
    public var isUserInitiated: Bool?
    public var apiName: String?
    
    public init() {
        
    }
}

public struct UsecaseQueue {
    public static let queue: DispatchQueue = DispatchQueue(label: Bundle.main.bundleIdentifier!, attributes: .concurrent)
}

open class ZUsecase<CustomRequest: Request, CustomResponse: Response>: NSObject {

    public final func execute(request: CustomRequest, callback: @escaping (_ response: CustomResponse) -> Void = { _ in }) {
        UsecaseQueue.queue.async { [weak self] in
            self?.run(request: request, callback: callback)
        }
    }

    open func run(request: CustomRequest, callback: @escaping (_ response: CustomResponse) -> Void) {

    }

    public final func invoke(callback:@escaping (_ response: CustomResponse) -> Void, response: CustomResponse) {
        if Thread.isMainThread {
            callback(response)
        } else {
            DispatchQueue.main.async(execute: {
                callback(response)
            })
        }

    }

    deinit { }
}
