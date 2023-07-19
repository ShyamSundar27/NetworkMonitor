//
//  DatabasePool.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 08/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public final class DatabasePool: VTDatabase {
    let writer: DatabaseQueue
    private var readerConfig: Configuration
    private var readerPool: Pool<DatabaseQueue>!
    public let storageLocation: StorageLocation
    
    private var queue: DispatchQueue
    
    private var schemaCache: DatabaseSchemaCache
    private var attachedDatabases: ReadWriteBox<[String: (path: String, key: Configuration.Key?)]> = ReadWriteBox([:])
    private var collations: Set<DatabaseCollation> = []
    private var functions: Set<DatabaseFunction> = []
    
    init(storageLocation: StorageLocation, configuration: Configuration, writeQueue: DispatchQueue?, schemaCache: DatabaseSchemaCache) throws {
        self.storageLocation = storageLocation
        self.schemaCache = schemaCache
        
        writer = try DatabaseQueue(storageLocation: storageLocation, configuration: configuration, queue: writeQueue, schemaCache: schemaCache)
        queue = DispatchQueue(label: "VTDB.DBPool.common-\(UUID().uuidString)")
        readerConfig = configuration
        readerConfig.readonly = true
        readerConfig.defaultTransactionType = .deferred
        readerConfig.threadingMode = .multiThread
        readerPool = try Pool(maximumCount: readerConfig.maximumReaderCount, makeElement: { [unowned self] in
            let reader = try DatabaseQueue(storageLocation: storageLocation, configuration: self.readerConfig, queue: nil, schemaCache: self.schemaCache)
            try reader.inDatabase { db in
                try self.attachedDatabases.read { dbs in
                    for (dbName, info) in dbs { try db.attachDatabase(from: info.path, withName: dbName, andKey: info.key) }
                }
                try self.collations.forEach { try db.create(collation: $0) }
                try self.functions.forEach { try db.add(function: $0) }
            }
            return reader
        })
        
        if configuration.readonly { return }
        
        try write { db in
            let journalMode: String = try db.query("PRAGMA journal_mode = WAL")
            guard journalMode == "wal" else {
                throw DatabaseError(message: "Could not activate WAL mode at path: \(path)")
            }
            try db.execute("PRAGMA synchronous = NORMAL")
            
            if !FileManager.default.fileExists(atPath: path + "-wal") {
                // Create the -wal file if it does not exist yet.
                let tableName = "VTDB"+UUID().uuidString.replacingOccurrences(of: "-", with: "")
                try db.execute("CREATE TABLE \(tableName) (id INTEGER PRIMARY KEY); DROP TABLE \(tableName);")
            }
        }
    }
    
    public convenience init(path: String, configuration: Configuration = Configuration(), writeQueue: DispatchQueue? = nil) throws {
        try self.init(storageLocation: .onDisk(path: path), configuration: configuration, writeQueue: writeQueue, schemaCache: SharedDatabaseSchemaCache())
    }
    
    public func releaseMemory() {
        schemaCache.clear()
        writer.releaseMemory()
        readerPool.forEach { $0.releaseMemory() }
        readerPool.clear()
    }
    
    public func write<T>(_ block: (Database) throws -> T) rethrows -> T {
        return try writer.inDatabase{ db in
            try block(db)
        }
    }
    
    public func writeInTransaction(_ block: @escaping (Database) throws -> Database.TransactionCompletion) rethrows {
        try writer.inTransaction(.deferred) { db in
            try block(db)
        }
    }
    
    public func read<T>(_ block: (Database) throws -> T) throws -> T {
        return try readerPool.get { reader in
            var result: T?
            try reader.inDatabase { db in
                result = try block(db)
            }
            return result!
        }
    }
    
    public func attachDatabase(fromPath path: String, withName name: String, andKey key: Configuration.Key?) throws {
        var attachError: Error?
        try queue.sync {
            var alreadyAttached = false
            try attachedDatabases.read { dbs in
                if let attachedPath = dbs[name]?.path {
                    if path == attachedPath {
                        alreadyAttached = true
                        return
                    } else {
                        throw DatabaseAttachError.schemaAlreadyInUse(name)
                    }
                }
            }
            if alreadyAttached { return }
            do {
                try writer.inDatabase { db in
                    try db.attachDatabase(from: path, withName: name, andKey: key)
                }
            
                try readerPool.forEach { dbQueue in
                    try dbQueue.inDatabase { db in
                        try db.attachDatabase(from: path, withName: name, andKey: key)
                    }
                }
                attachedDatabases.write { dbs in
                    dbs[name] = (path, key)
                }
            } catch {
                attachError = error
            }
        }
        if let error = attachError {
            try? detachDatabase(named: name)
            throw error
        }
    }
    
    public func detachDatabase(named name: String) throws {
        try queue.sync {
            var alreadyDetached = false
            var fistError: Error?
            attachedDatabases.write { dbs in
                if dbs.removeValue(forKey: name) == nil {
                    alreadyDetached = true
                }
            }
            if alreadyDetached { return }
            do {
                try writer.inDatabase { db in
                    try db.detachDatabase(named: name)
                }
            } catch DatabaseAttachError.schemaNotFound {
                // ignore
            } catch {
                if fistError == nil {
                    fistError = error
                }
            }
            
            readerPool.forEach{ dbQueue in
                do {
                    try dbQueue.inDatabase { db in
                        try db.detachDatabase(named: name)
                    }
                } catch DatabaseAttachError.schemaNotFound {
                    // ignore
                } catch {
                    if fistError == nil {
                        fistError = error
                    }
                }
            }
            if let error = fistError {
                throw error
            }
        }
    }
    
    public func getAttachedDatabases() -> [String: String] {
        return attachedDatabases.read { dbs in
            return dbs.reduce(into: [String: String]()) {
                $0[$1.key] = $1.value.path
            }
        }
    }
    
    private func copy(from source: Database) throws {
        try writer.copy(from: source)
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
        try queue.sync {
            do {
                try writer.create(collation: collation)
                try readerPool.forEach { try $0.create(collation: collation) }
                collations.update(with: collation)
            } catch {
                writer.remove(collation: name)
                readerPool.forEach { $0.remove(collation: name) }
                throw error
            }
        }
    }
    
    public func remove(collation name: String) {
        queue.sync {
            writer.remove(collation: name)
            readerPool.forEach { $0.remove(collation: name) }
            collations.remove(DatabaseCollation(name: name, function: { _,_ in return ComparisonResult.orderedSame }))
        }
    }
    
    public func addFunction(named name: String, argumentCount: Int8?, deterministic: Bool, function: @escaping ([DatabaseValue]) throws -> DatabaseValueConvertible?) throws {
        try queue.sync {
            let dbFunction = DatabaseFunction(name: name, argumentCount: argumentCount, deterministic: deterministic, function: function)
            do {
                functions.insert(dbFunction)
                try writer.addFunction(named: name, argumentCount: argumentCount, deterministic: deterministic, function: function)
                try readerPool.forEach {
                    try $0.addFunction(named: name, argumentCount: argumentCount, deterministic: deterministic, function: function)
                }
            } catch {
                functions.remove(dbFunction)
                writer.removeFunction(named: name, argumentCount: argumentCount)
                readerPool.forEach { $0.removeFunction(named: name, argumentCount: argumentCount) }
                throw error
            }
        }
    }
    
    public func removeFunction(named name: String, argumentCount: Int8?) {
        queue.sync {
            writer.removeFunction(named: name, argumentCount: argumentCount)
            readerPool.forEach { $0.removeFunction(named: name, argumentCount: argumentCount) }
        }
    }
    
    public func openConnection() throws {
        try queue.sync {
            try writer.openConnection()
            try readerPool.forEach { try $0.openConnection() }
        }
    }
    
    public func closeConnection() {
        queue.sync {
            writer.closeConnection()
            readerPool.forEach { $0.closeConnection() }
        }
    }
}
