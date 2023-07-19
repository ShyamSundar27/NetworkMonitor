//
//  Persistable.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 08/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation

public typealias Container = [String: DatabaseValueConvertible?]

// MARK: PersistenceError

/// An error thrown by a type that adopts Persistable.
public enum PersistenceError: Error {
    case recordNotFound(Persistable)
}

extension PersistenceError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .recordNotFound(let persistable):
            return "Not found: \(persistable)"
        }
    }
}

public protocol Persistable: TableMapping {
    func encode(to container: inout Container)
}

extension Persistable {
    public func insert(_ db: Database) throws {
        var container: Container = [:]
        encode(to: &container)
        try db.insert(intoTable: Self.databaseTableName, values: container)
    }
    
    func insert(_ db: Database, container: Container) throws {
        try db.insert(intoTable: Self.databaseTableName, values: container)
    }
    
    public func update(_ db: Database) throws {
        guard try exists(db) else {
            throw PersistenceError.recordNotFound(self)
        }
        var container: Container = [:]
        encode(to: &container)
        let criteria = try getPrimaryKeys(db, container: container)
        try UpdateQuery(table: Self.databaseTableName).set(container).filter(criteria).execute(db)
    }
    
    func update(_ db: Database, container: Container) throws {
        guard try exists(db, container: container) else {
            throw PersistenceError.recordNotFound(self)
        }
        let criteria = try getPrimaryKeys(db, container: container)
        let container = container.filter {
            if let _ = criteria[$0.key] {
                return false
            }
            return true
        }
        try UpdateQuery(table: Self.databaseTableName).set(container).filter(criteria).execute(db)
    }
    
    public func save(_ db: Database) throws {
        var container: Container = [:]
        encode(to: &container)
        do {
            try update(db, container: container)
        } catch PersistenceError.recordNotFound {
            try insert(db, container: container)
        }
    }
    
    public func delete(_ db: Database) throws {
        var container: Container = [:]
        encode(to: &container)
        let criteria = try getPrimaryKeys(db, container: container)
        try DeleteQuery(table: Self.databaseTableName).filter(criteria).execute(db)
    }
    
    public func exists(_ db: Database) throws -> Bool {
        var container: Container = [:]
        encode(to: &container)
        let criteria = try getPrimaryKeys(db, container: container)
        return try SelectQuery(table: Self.databaseTableName).filter(criteria).fetchCount(db) > 0
    }
    
    func exists(_ db: Database, container: Container) throws -> Bool {
        let criteria = try getPrimaryKeys(db, container: container)
        return try SelectQuery(table: Self.databaseTableName).filter(criteria).fetchCount(db) > 0
    }
    
    func getPrimaryKeys(_ db: Database, container: Container) throws -> [String: DatabaseValueConvertible?] {
        if let primaryKeys = try db.primaryKey(of: Self.databaseTableName) {
            let dict = container.filter { primaryKeys.contains($0.key) }
            return dict
        } else {
            throw PersistenceError.recordNotFound(self)
        }
    }    
}

extension Persistable {
    public static func insert(_ records: [Self], in db: Database) throws {
        guard records.count > 0 else { return }
        
        var containers: [Container] = []
        records.forEach {
            var container: Container = [:]
            $0.encode(to: &container)
            containers.append(container)
        }
        
        try db.insert(intoTable: Self.databaseTableName, values: containers)
    }
}
