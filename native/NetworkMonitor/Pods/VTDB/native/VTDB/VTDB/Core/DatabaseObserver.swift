//
//  DatabaseObserver.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 04/05/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation
#if SQLCipher
import SQLCipher
#else
import SQLite3
#endif

extension Database {
    func addDatabaseObserver() {
        databaseObserver = DatabaseObserver(database: self)
        sqlite3_update_hook(sqliteConnection, { pointer, type, databaseName, tableName, rowID in
            guard let pointer = pointer else { return }
            let observer = Unmanaged<DatabaseObserver>.fromOpaque(pointer).takeUnretainedValue()
            observer.didChange(type: type, databaseName: databaseName, tableName: tableName, rowID: rowID)
        }, Unmanaged<DatabaseObserver>.passUnretained(databaseObserver!).toOpaque())
    }
    
    func removeDatabaseObserver() {
        databaseObserver?.removeAll()
        sqlite3_update_hook(sqliteConnection, nil, nil)
        databaseObserver = nil
    }
    
    func observe(database: String?, table: String, forEvents event: Set<DatabaseEvent>? = nil, block: (SimpleObserver) -> Void) {
        let simpleObserver = SimpleObserver(databaseName: database, tableName: table, events: event ?? [.insert, .update, .delete])
        if databaseObserver == nil {
            addDatabaseObserver()
        }
        databaseObserver?.add(defaultObserver: DefaultObserver(simpleObserver: simpleObserver))
        block(simpleObserver)
    }
    
    func removeObserver(database: String?, table: String) {
        let simpleObserver = SimpleObserver(databaseName: database, tableName: table, events: [])
        databaseObserver?.remove(defaultObserver: DefaultObserver(simpleObserver: simpleObserver))
        if let databaseObserver = databaseObserver, databaseObserver.defaultObservers.isEmpty
            && databaseObserver.transactionObservers.isEmpty {
            removeDatabaseObserver()
        }
    }
    
    func add(transactionObserver: TransactionObserver) {
        if databaseObserver == nil {
            addDatabaseObserver()
        }
        databaseObserver?.add(transactionObserver: transactionObserver)
    }
    
    func add(simpleObserver: SimpleObserver) {
        if databaseObserver == nil {
            addDatabaseObserver()
        }
        databaseObserver?.add(defaultObserver: DefaultObserver(simpleObserver: simpleObserver))
    }
    
    func remove(transactionObserver: TransactionObserver) {
        databaseObserver?.remove(transactionObserver: transactionObserver)
        if let databaseObserver = databaseObserver, databaseObserver.defaultObservers.isEmpty
            && databaseObserver.transactionObservers.isEmpty {
            removeDatabaseObserver()
        }
    }
    
    func remove(simpleObserver: SimpleObserver) {
        databaseObserver?.remove(defaultObserver: DefaultObserver(simpleObserver: simpleObserver))
    }
    
}

public protocol TransactionObserver: AnyObject {
    func observeEvent(type: DatabaseEvent, databaseName: String, tableName: String) -> Bool
    func didChange(type: DatabaseEvent, databaseName: String, tableName: String, rowID: Int)
    func didCommit(_: Database)
    func didRollback(_: Database)
}

public enum DatabaseEvent {
    case insert
    case update
    case delete
    
    public var rawValue: Int32 {
        switch self {
        case .insert: return SQLITE_INSERT
        case .update: return SQLITE_UPDATE
        case .delete: return SQLITE_DELETE
        }
    }
    
    public init?(rawValue: Int32) {
        switch rawValue {
        case DatabaseEvent.insert.rawValue: self = .insert
        case DatabaseEvent.update.rawValue: self = .update
        case DatabaseEvent.delete.rawValue: self = .delete
        default: return nil
        }
    }
}

public final class DatabaseObserver {
    enum TransactionState {
        case none
        case commit
        case rollback
    }
    
    unowned let database: Database
    var transactionObserversToNotify: Set<Int> = []
    var transactionObservers: [Int: TransactionObserver] = [:]
    var defaultObservers: Set<DefaultObserver> = []
    var defaultObserversToNotify: Set<DefaultObserver> = []
    
    var notifyObservers: Bool = false
    var transactionState: TransactionState = .none {
        didSet {
            check()
        }
    }
    var statementReset: Bool = false {
        didSet {
            check()
        }
    }
    
    public init(database: Database) {
        self.database = database
        setup()
    }
    
    func setup() {
        sqlite3_commit_hook(database.sqliteConnection, { pointer in
            guard let pointer = pointer else { return 0 }
            let observer = Unmanaged<DatabaseObserver>.fromOpaque(pointer).takeUnretainedValue()
            observer.transactionState = .commit
            return 0
        }, Unmanaged<DatabaseObserver>.passUnretained(self).toOpaque())
        
        sqlite3_rollback_hook(database.sqliteConnection, { pointer in
            guard let pointer = pointer else { return }
            let observer = Unmanaged<DatabaseObserver>.fromOpaque(pointer).takeUnretainedValue()
            observer.transactionState = .rollback
        }, Unmanaged<DatabaseObserver>.passUnretained(self).toOpaque())
    }
    
    func check() {
        if statementReset && transactionState != .none {
            statementReset = false
            let state = transactionState
            transactionState = .none
            switch state {
            case .commit: didCommit()
            case .rollback: didRollback()
            case .none: break
            }
        }
    }
    
    func didChange(type: Int32, databaseName: UnsafePointer<Int8>?, tableName: UnsafePointer<Int8>?, rowID: sqlite3_int64) {
        notifyObservers = true
        guard let type = DatabaseEvent(rawValue: type) else { return }
        if databaseName == nil || tableName == nil { return }
        let databaseName = String(cString: databaseName!).lowercased()
        let tableName = String(cString: tableName!).lowercased()
        let rowID = Int(rowID)
        transactionObservers.forEach { id, observer in
            if observer.observeEvent(type: type, databaseName: databaseName, tableName: tableName) {
                transactionObserversToNotify.insert(id)
                observer.didChange(type: type, databaseName: databaseName, tableName: tableName, rowID: rowID)
            }
        }
        defaultObservers.forEach {
            if $0.observeEvent(type: type, databaseName: databaseName, tableName: tableName) {
                defaultObserversToNotify.insert($0)
                $0.didChange(type: type, databaseName: databaseName, tableName: tableName, rowID: rowID)
            }
        }
    }
    
    func didCommit() {
        guard notifyObservers else {
            return
        }
        notifyObservers = false
        let observerIds = transactionObserversToNotify
        let defaultObservers = defaultObserversToNotify
        transactionObserversToNotify.removeAll()
        defaultObserversToNotify.removeAll()
        observerIds.forEach { transactionObservers[$0]?.didCommit(database) }
        defaultObservers.forEach { $0.didCommit(database) }
    }
    
    func didRollback() {
        guard notifyObservers else {
            return
        }
        notifyObservers = false
        let observerIds = transactionObserversToNotify
        let defaultObservers = defaultObserversToNotify
        transactionObserversToNotify.removeAll()
        defaultObserversToNotify.removeAll()
        observerIds.forEach { transactionObservers[$0]?.didRollback(database) }
        defaultObservers.forEach { $0.didRollback(database) }
    }
    
    func add(transactionObserver: TransactionObserver) {
        transactionObservers.updateValue(transactionObserver, forKey: transactionObservers.count)
    }
    
    func add(defaultObserver: DefaultObserver) {
        defaultObservers.update(with: defaultObserver)
    }
    
    func remove(defaultObserver: DefaultObserver) {
        defaultObservers.remove(defaultObserver)
    }
    
    func remove(transactionObserver: TransactionObserver) {
        var observerToRemove: [Int] = []
        for (index, ob) in transactionObservers {
            if transactionObserver === ob {
                observerToRemove.append(index)
            }
        }
        
        observerToRemove.forEach { index in
            transactionObserversToNotify.remove(index)
            transactionObservers[index] = nil
        }
    }
    
    func removeAll() {
        sqlite3_commit_hook(database.sqliteConnection, nil, nil)
        sqlite3_update_hook(database.sqliteConnection, nil, nil)
        transactionObservers.removeAll()
        defaultObservers.removeAll()
        transactionObserversToNotify.removeAll()
        defaultObserversToNotify.removeAll()
    }
}

public struct TransactionChanges {
    public var insertedRowID: [String: Set<Int>] = [:]
    public var deletedRowID: [String: Set<Int>] = [:]
    public var updatedRowID: [String: Set<Int>] = [:]
    
    public init() {}
    
    public mutating func reset() {
        insertedRowID.removeAll()
        deletedRowID.removeAll()
        updatedRowID.removeAll()
    }
    
    public mutating func addChanges(of type: DatabaseEvent, in table: String, rowId: Int) {
        switch type {
        case .insert:
            if let _ = insertedRowID[table] {
                insertedRowID[table]?.insert(rowId)
            } else {
                insertedRowID[table] = [rowId]
            }
        case .delete:
            if let _ = deletedRowID[table] {
                deletedRowID[table]?.insert(rowId)
            } else {
                deletedRowID[table] = [rowId]
            }
        case .update:
            if let _ = updatedRowID[table] {
                updatedRowID[table]?.insert(rowId)
            } else {
                updatedRowID[table] = [rowId]
            }
        }
    }
}

public struct SimpleObserver {
    public var onChange: ((DatabaseEvent, String, String, Int) -> Void)?
    public var onCommit: ((Database, TransactionChanges) -> Void)?
    public var onRollback: ((Database, TransactionChanges) -> Void)?
    public let databaseName: String
    public let tableName: String
    private let id: String
    public let events: Set<DatabaseEvent>
    
    public init(databaseName: String? = nil, tableName: String, events: Set<DatabaseEvent> = []) {
        self.databaseName = databaseName?.lowercased() ?? VTDBConstants.primaryDatabase
        self.tableName = tableName.lowercased()
        if events.isEmpty {
            self.events = [.insert, .update, .delete]
        } else {
            self.events = events
        }
        id = self.databaseName + "." + self.tableName
    }
}

extension SimpleObserver: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: SimpleObserver, rhs: SimpleObserver) -> Bool {
        return lhs.id == rhs.id
    }
}

class DefaultObserver: TransactionObserver {
    var simpleObserver: SimpleObserver
    var transactionChanges = TransactionChanges()
    init(simpleObserver: SimpleObserver) {
        self.simpleObserver = simpleObserver
    }
    
    func observeEvent(type: DatabaseEvent, databaseName: String, tableName: String) -> Bool {
        return tableName == simpleObserver.tableName
            && databaseName == simpleObserver.databaseName
            && simpleObserver.events.contains(type)
    }
    
    func didChange(type: DatabaseEvent, databaseName: String, tableName: String, rowID: Int) {
        transactionChanges.addChanges(of: type, in: tableName, rowId: rowID)
        simpleObserver.onChange?(type, simpleObserver.databaseName, simpleObserver.tableName, rowID)
    }
    
    func didCommit(_ db: Database) {
        let changes = transactionChanges
        transactionChanges.reset()
        simpleObserver.onCommit?(db, changes)
    }
    
    func didRollback(_ db: Database) {
        let changes = transactionChanges
        transactionChanges.reset()
        simpleObserver.onRollback?(db, changes)
    }
}

extension DefaultObserver: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(simpleObserver)
    }
    
    static func == (lhs: DefaultObserver, rhs: DefaultObserver) -> Bool {
        return lhs.simpleObserver == rhs.simpleObserver
    }
}
