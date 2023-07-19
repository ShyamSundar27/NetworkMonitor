//
//  VTDatabase.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 19/02/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

public protocol VTDatabase: AnyObject {
    var storageLocation: StorageLocation { get }
    var path: String { get }
    
    func read<T>(_ block: (Database) throws -> T) throws -> T
    func write<T>(_ block: (Database) throws -> T) rethrows -> T
    func writeInTransaction(_ block: @escaping (Database) throws -> Database.TransactionCompletion) rethrows
    func releaseMemory()
    
    // Attach
    func attachDatabase(fromPath path: String, withName name: String, andKey: Configuration.Key?) throws
    func detachDatabase(named name: String) throws
    func getAttachedDatabases() -> [String: String]
    
    // Backup
    func copy(from source: VTDatabase) throws
    
    // Collation
    func create(collation name: String, function: @escaping (String, String) -> ComparisonResult) throws
    func remove(collation name: String)
    
    // Observer
    func add(transactionObserver: TransactionObserver)
    func add(simpleObserver: SimpleObserver)
    func remove(transactionObserver: TransactionObserver)
    func remove(simpleObserver: SimpleObserver)
    func removeAllObserver()
    
    // Function
    func addFunction(named: String, argumentCount: Int8?, deterministic: Bool, function: @escaping ([DatabaseValue]) throws -> DatabaseValueConvertible?) throws
    func removeFunction(named: String, argumentCount: Int8?)
    
    // connection
    func openConnection() throws
    func closeConnection() 
}

// MARK: Observer Helper
public extension VTDatabase {
    var path: String {
        return storageLocation.path
    }
    
    func add(transactionObserver: TransactionObserver) {
        write { db in
            db.add(transactionObserver: transactionObserver)
        }
    }
    
    func add(simpleObserver: SimpleObserver) {
        write { db in
            db.add(simpleObserver: simpleObserver)
        }
    }
    
    func remove(transactionObserver: TransactionObserver) {
        write { db in
            db.remove(transactionObserver: transactionObserver)
        }
    }
    
    func remove(simpleObserver: SimpleObserver) {
        write { db in
            db.remove(simpleObserver: simpleObserver)
        }
    }
    
    func removeAllObserver() {
        write { db in
            db.removeDatabaseObserver()
        }
    }
}

// MARK: Custom Functions Helpers
public extension VTDatabase {
    func addFunction(named name: String, function: @escaping ([DatabaseValue]) throws -> DatabaseValueConvertible?) throws {
        try addFunction(named: name, argumentCount: nil, deterministic: false, function: function)
    }
    
    func removeFunction(named name: String) {
        removeFunction(named: name, argumentCount: nil)
    }
}

// MARK: Attach Database Helpers
public extension VTDatabase {
    func attachDatabase(fromPath path: String, withName name: String) throws {
        try attachDatabase(fromPath: path, withName: name, andKey: nil)
    }
    
    #if SQLCipher
    func attachDatabase(fromPath path: String, withName name: String, andKey passphrase: String?) throws {
        var key: Configuration.Key?
        if let passphrase = passphrase {
            key = .passphrase(passphrase)
        }
        try attachDatabase(fromPath: path, withName: name, andKey: key)
    }
    
    func attachDatabase(fromPath path: String, withName name: String, andKey rawKey: Data) throws {
        try attachDatabase(fromPath: path, withName: name, andKey: .rawKey(rawKey))
    }
    #endif
}
