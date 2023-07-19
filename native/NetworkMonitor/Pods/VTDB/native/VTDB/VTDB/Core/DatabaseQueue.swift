//
//  DatabaseQueue.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 08/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public final class DatabaseQueue: VTDatabase {
    let database: Database
    public let storageLocation: StorageLocation
    
    private let id: String
    private let queue: DispatchQueue
    
    private var schemaCache: DatabaseSchemaCache
    private var attachedDatabases: ReadWriteBox<[String: String]> = ReadWriteBox([:])
    private var collations: Set<DatabaseCollation> = []
    
    init(storageLocation: StorageLocation, configuration: Configuration, queue: DispatchQueue?, schemaCache: DatabaseSchemaCache) throws {
        var config = configuration
        config.threadingMode = .multiThread
        self.storageLocation = storageLocation
        self.schemaCache = schemaCache
        database = try Database(storageLocation: storageLocation, configuration: config, schemaCache: schemaCache)
        let uuid = UUID()
        id = uuid.uuidString
        self.queue = queue ?? DispatchQueue(label: "VTDB.DBQueue-\(uuid.uuidString)")
    }
    
    public convenience init(path: String, configuration: Configuration = Configuration(), queue: DispatchQueue? = nil) throws {
        try self.init(storageLocation: .onDisk(path: path), configuration: configuration, queue: queue)
    }
    
    public convenience init(storageLocation: StorageLocation, configuration: Configuration = Configuration(), queue: DispatchQueue? = nil) throws {
        try self.init(storageLocation: storageLocation, configuration: configuration, queue: queue, schemaCache: SharedDatabaseSchemaCache())
    }
    
    public func releaseMemory() {
        schemaCache.clear()
        inDatabase { $0.releaseMemory() }
    }
    
    public func inDatabase<T>(_ block: (Database) throws -> T) rethrows -> T {
        return try queue.sync {
            return try block(database)
        }
    }
    
    public func inTransaction(_ type: Database.TransactionType = .deferred, _ block: @escaping (Database) throws -> Database.TransactionCompletion) rethrows {
        try inDatabase { db in
            try db.transaction(type) {
                try block(db)
            }
        }
    }
    
    public func read<T>(_ block: (Database) throws -> T) rethrows -> T {
        return try inDatabase { db in
            if #available(iOS 8.2, OSX 10.10, *) {
                try db.execute("PRAGMA query_only = 1")
                return try throwFirstError {
                    try block(db)
                } finally: {
                    try db.execute("PRAGMA query_only = 0")
                }
            } else {
                return try block(db)
            }
        }
    }
    
    public func write<T>(_ block: (Database) throws -> T) rethrows -> T {
        return try inDatabase(block)
    }
    
    public func writeInTransaction(_ block: @escaping (Database) throws -> Database.TransactionCompletion) rethrows {
        return try inTransaction(.deferred, block)
    }
    
    public func attachDatabase(fromPath path: String, withName name: String, andKey key: Configuration.Key?) throws {
        try queue.sync {
            var alreadyAttached = false
            try attachedDatabases.read { dbs in
                if let attachedPath = dbs[name] {
                    if attachedPath == path {
                        alreadyAttached = true
                        return
                    } else {
                        throw DatabaseAttachError.schemaAlreadyInUse(name)
                    }
                }
            }
            if alreadyAttached { return }
            try inDatabase { db in
                try db.attachDatabase(from: path, withName: name, andKey: key)
            }
            attachedDatabases.write { dbs in
                dbs[name] = path
            }
        }
    }
    
    public func detachDatabase(named name: String) throws {
        try queue.sync {
            var alreadyDeatched = false
            attachedDatabases.read { dbs in
                if dbs[name] == nil {
                    alreadyDeatched = true
                    return
                }
            }
            if alreadyDeatched { return }
            defer {
                attachedDatabases.write { dbs in
                    dbs[name] = nil
                }
            }
            do {
                try inDatabase { db in
                    try db.detachDatabase(named: name)
                }
            } catch DatabaseAttachError.schemaNotFound {
                // ignore
            }
        }
    }
    
    public func getAttachedDatabases() -> [String: String] {
        return attachedDatabases.read { dbs in
            return dbs
        }
    }
    
    public func copy(from source: Database) throws {
        try queue.sync {
            try database.copy(from: source)
        }
    }
    
    public func copy(from source: VTDatabase) throws {
        try queue.sync {
            switch source {
            case let dbPool as DatabasePool:
                try copy(from: dbPool.writer.database)
            case let dbQueue as DatabaseQueue:
                try copy(from: dbQueue.database)
            default:
                return
            }
        }
    }
    
    public func create(collation name: String, function: @escaping (String, String) -> ComparisonResult) throws {
        let collation = DatabaseCollation(name: name, function: function)
        try create(collation: collation, cache: true)
    }
    
    public func remove(collation name: String) {
        write { db in
            db.remove(collation: name)
            collations.remove(DatabaseCollation(name: name, function: { _,_ in return ComparisonResult.orderedSame }))
        }
    }
    
    func create(collation: DatabaseCollation, cache: Bool = false) throws {
        try write { db in
            try db.create(collation: collation)
            if cache {
                collations.update(with: collation)
            }
        }
    }
    
    public func addFunction(named: String, argumentCount: Int8?, deterministic: Bool, function: @escaping ([DatabaseValue]) throws -> DatabaseValueConvertible?) throws {
        try queue.sync {
            try inDatabase { db in
                try db.addFunction(named: named, argumentCount: argumentCount, deterministic: deterministic, function: function)
            }
        }
    }
    
    public func removeFunction(named: String, argumentCount: Int8?) {
        queue.sync {
            inDatabase { db in
                db.removeFunction(named: named, argumentCount: argumentCount)
            }
        }
    }
    
    public func openConnection() throws {
        try queue.sync {
            try database.openConnection()
        }
    }
    
    public func closeConnection() {
        queue.sync {
            database.closeConnection()
        }
    }
}

// MARK: Hashable
extension DatabaseQueue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension DatabaseQueue: Equatable {
    public static func ==(lhs: DatabaseQueue, rhs: DatabaseQueue) -> Bool {
        return lhs.id == rhs.id
    }
}
