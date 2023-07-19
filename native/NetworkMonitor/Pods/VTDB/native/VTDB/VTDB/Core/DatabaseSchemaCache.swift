//
//  DatabaseSchemaCache.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 20/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

// The protocol for schema cache.
//
// This protocol must not contain values that are valid for a single connection
// only, because several connections can share the same schema cache.
//
// Statements can't be cached here, for example.
import Foundation

protocol DatabaseSchemaCache: AnyObject {
    func clear()

    func primaryKey(_ table: String) -> [String]?
    func set(primaryKey: [String]?, forTable table: String)
    
    func columnInfos(_ table: String) -> [ColumnInfo]?
    func set(columnInfos: [ColumnInfo]?, forTable table: String)
    
    func columnTypes(table: String) -> [String: Database.ColumnType]?
    func set(columnTypes: [String: Database.ColumnType]?, forTable table: String)
    
    func columnTypes(sql: String) -> [String: Database.ColumnType]?
    func set(columnTypes: [String: Database.ColumnType]?, forSQL sql: String)
    #if SQLEncrypted
    func encryptedColumns(_ table: String) -> Set<String>?
    func set(encryptedColumns: Set<String>?, forTable table: String)
    #endif
}

// A thread-safe database schema cache
final class SharedDatabaseSchemaCache: DatabaseSchemaCache {
    private var primaryKeyCache: NSCache<NSString, Wrapper<[String]>> = NSCache()
    private var columnInfoCache: NSCache<NSString, Wrapper<[ColumnInfo]>> = NSCache()
    private var columnTypeCache: NSCache<NSString, Wrapper<[String: Database.ColumnType]>> = NSCache()
    private var queryColumnTypeCache: NSCache<NSString, Wrapper<[String: Database.ColumnType]>> = NSCache()
    private var encryptedColumnCache: NSCache<NSString, Wrapper<Set<String>>> = NSCache()
    
    func clear() {
        primaryKeyCache.removeAllObjects()
        columnInfoCache.removeAllObjects()
        columnTypeCache.removeAllObjects()
        queryColumnTypeCache.removeAllObjects()
        encryptedColumnCache.removeAllObjects()
    }
    
    private func getValue<T>(forKey key: String, from cache: NSCache<NSString, Wrapper<T>>) -> T? {
        return cache.object(forKey: key.lowercased() as NSString)?.value
    }
    
    private func set<T>(_ value: T?, forKey key: String, in cache: NSCache<NSString, Wrapper<T>>) {
        if let value = value {
            cache.setObject(Wrapper(value), forKey: key.lowercased() as NSString)
        } else {
            cache.removeObject(forKey: key.lowercased() as NSString)
        }
    }
    
    func primaryKey(_ table: String) -> [String]? {
        return getValue(forKey: table, from: primaryKeyCache)
    }
    
    func set(primaryKey: [String]?, forTable table: String) {
        set(primaryKey, forKey: table, in: primaryKeyCache)
    }
    
    func columnInfos(_ table: String) -> [ColumnInfo]? {
        return getValue(forKey: table, from: columnInfoCache)
    }
    
    func set(columnInfos: [ColumnInfo]?, forTable table: String) {
        set(columnInfos, forKey: table, in: columnInfoCache)
    }
    
    func columnTypes(table: String) -> [String: Database.ColumnType]? {
        return getValue(forKey: table, from: columnTypeCache)
    }
    
    func set(columnTypes: [String: Database.ColumnType]?, forTable table: String) {
        set(columnTypes, forKey: table, in: columnTypeCache)
    }
    
    func columnTypes(sql: String) -> [String : Database.ColumnType]? {
        return getValue(forKey: sql, from: queryColumnTypeCache)
    }
    
    func set(columnTypes: [String : Database.ColumnType]?, forSQL sql: String) {
        set(columnTypes, forKey: sql, in: queryColumnTypeCache)
    }
    
    func encryptedColumns(_ table: String) -> Set<String>? {
        return getValue(forKey: table, from: encryptedColumnCache)
    }
    
    func set(encryptedColumns: Set<String>?, forTable table: String) {
        set(encryptedColumns, forKey: table, in: encryptedColumnCache)
    }
}
