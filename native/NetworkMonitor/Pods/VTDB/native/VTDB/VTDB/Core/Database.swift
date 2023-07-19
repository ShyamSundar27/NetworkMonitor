//
//  Database.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 08/12/17.
//  Copyright © 2017 Zoho Corp. All rights reserved.
//

import Foundation
#if SQLCipher
import SQLCipher
#else
import SQLite3
#endif

public typealias SQLiteConnection = OpaquePointer
public typealias SQL = String

public enum StorageLocation {
    case temporary
    case inMemory(shared: Bool)
    case onDisk(path: String)
}

extension StorageLocation {
    var path: String {
        switch self {
        case .temporary:
            return ""
        case .inMemory(let shared):
            if shared {
                return "file::memory:?cache=shared"
            } else {
                return ":memory:"
            }
        case .onDisk(let path):
            return path
        }
    }
}

public final class Database {
    
    var sqliteConnection: SQLiteConnection
    public let configuration: Configuration
    public let storageLocation: StorageLocation
    public var path: String {
        return storageLocation.path
    }
    
    public var lastInsertedRowID: Int64 {
        return sqlite3_last_insert_rowid(sqliteConnection)
    }
    
    public var changesCount: Int {
        return Int(sqlite3_changes(sqliteConnection))
    }
    
    public var totalChangesCount: Int {
        return Int(sqlite3_total_changes(sqliteConnection))
    }
    
    public var isInsideTransaction: Bool {
        return sqlite3_get_autocommit(sqliteConnection) == 0
    }
    #if SQLEncrypted
    var encryption: Encryption?
    #endif
    var schemaCache: DatabaseSchemaCache
    var databaseObserver: DatabaseObserver?
    private var busyCallback: BusyCallback?
    
    // Errors
    var lastErrorCode: Int32 { return sqlite3_errcode(sqliteConnection) }
    var lastExtendedErrorCode: Int32 { return sqlite3_extended_errcode(sqliteConnection) }
    var lastErrorMessage: String? { return String(cString: sqlite3_errmsg(sqliteConnection)) }
    
    init(storageLocation: StorageLocation, configuration: Configuration, schemaCache: DatabaseSchemaCache) throws {
        let sqliteConnection = try Database.openConnection(path: storageLocation.path, flags: configuration.SQLiteOpenFlags)
        self.storageLocation = storageLocation
        self.sqliteConnection = sqliteConnection
        self.configuration = configuration
        self.schemaCache = schemaCache
        try setup()
    }
    
    deinit {
        removeDatabaseObserver()
        Database.closeConnection(sqliteConnection)
    }
    
    public func releaseMemory() {
        sqlite3_db_release_memory(sqliteConnection)
    }
    
    public func execute(_ sql: SQL) throws {
        let code = sqlite3_exec(sqliteConnection, sql, nil, nil, nil)
        guard code == SQLITE_OK else {
            throw DatabaseError(code: code, message: lastErrorMessage, sql: sql)
        }
    }
    
    public func execute(_ sql: SQL, _ parameters: [Any?]) throws {
        let values = try castToList(parameters)
        try execute(sql, values)
    }
    
    public func execute(_ sql: SQL, _ parameters: [[Any?]]) throws {
        let values = try castToListOfList(parameters)
        try execute(sql, values)
    }
    
    public func execute(_ sql: SQL, _ parameters: DatabaseValueConvertible?... ) throws {
        try execute(sql, parameters)
    }
    
    public func execute(_ sql: SQL, _ parameters: [DatabaseValueConvertible?]) throws {
        let statement = try Statement(database: self, sql: sql)
        try statement.bind(parameters).run()
    }
    
    public func execute(_ sql: SQL, _ parameters: [[DatabaseValueConvertible?]]) throws {
        let statement = try Statement(database: self, sql: sql)
        for parameter in parameters {
            try statement.bind(parameter).run()
        }
    }
    
    public func execute(_ statement: Statement, _ parameters: DatabaseValueConvertible?...) throws {
        try statement.bind(parameters).run()
    }
    
    public func execute(_ statement: Statement, _ parameters: [DatabaseValueConvertible?]) throws {
        try statement.bind(parameters).run()
    }
    
    public func execute(_ statement: Statement, _ parameters: [String: DatabaseValueConvertible?]) throws {
        try statement.bind(parameters).run()
    }
    
    public func execute(_ sql: SQL, _ parameters: [String: DatabaseValueConvertible?]) throws {
        let statement = try Statement(database: self, sql: sql)
        try statement.bind(parameters).run()
    }
    
    public func execute(_ queryInterface: QueryInterfaceProtocol) throws {
        #if SQLEncrypted
        let statement = try Statement(database: self, sql: queryInterface.expressionSQL(self, encryptedColumns: []))
        #else
        let statement = try Statement(database: self, sql: queryInterface.expressionSQL)
        #endif
        try statement.bind(queryInterface.parameters).run()
    }
    
    /// User must ensure that all record have same signature otherwise an error will occur while binding
    public func execute(_ sql: SQL, _ parameters: [[String: DatabaseValueConvertible?]]) throws {
        let statement = try Statement(database: self, sql: sql)
        for parameter in parameters {
            try statement.bind(parameter).run()
        }
    }
    
    public func transaction(_ type: TransactionType? = nil, closure: () throws -> TransactionCompletion) throws {
        try beginTransaction(type ?? configuration.defaultTransactionType)
        var firstError: Error?
        var needRollback: Bool = false
        
        do {
            switch try closure() {
            case .commit:
                try commit()
            case .rollback:
                needRollback = true
            }
        } catch {
            firstError = error
            needRollback = true
        }
        
        do {
            if needRollback {
                try rollback()
            }
        } catch {
            if firstError == nil {
                firstError = error
            }
        }
        
        if let error = firstError {
            throw error
        }
        
    }
    
    private func beginTransaction(_ kind: TransactionType) throws {
        try execute("BEGIN \(kind.rawValue) TRANSACTION")
    }
    
    private func rollback() throws {
        if sqlite3_get_autocommit(sqliteConnection) == 0 {
            try execute("ROLLBACK TRANSACTION")
        }
    }
    
    private func commit() throws {
        try execute("COMMIT TRANSACTION")
    }
    
    public func attachDatabase(from path: String, withName name: String, andKey key: Configuration.Key? = nil) throws {
        do {
            if let key = key {
                try execute("ATTACH DATABASE '\(path)' AS '\(name)' KEY '\(key.plainKey)'")
            } else {
                try execute("ATTACH DATABASE '\(path)' AS '\(name)'")
            }
        } catch {
            if error.localizedDescription.contains("is already in use") {
                throw DatabaseAttachError.schemaAlreadyInUse(name)
            }
            throw error
        }
    }
    
    public func getAttachedDatabases() throws -> [DatabaseInfo] {
        var dbInfos: [DatabaseInfo] = try query("PRAGMA database_list")
        dbInfos.removeFirst()
        return dbInfos
    }
    
    public func detachDatabase(named name: String) throws {
        do {
            try execute("DETACH DATABASE '\(name)'")
        } catch {
            if error.localizedDescription.contains("no such database") {
                throw DatabaseAttachError.schemaNotFound(name)
            }
            throw error
        }
    }
    
    public func copy(from source: Database) throws {
        let copyConnection = sqlite3_backup_init(sqliteConnection, "main", source.sqliteConnection, "main")
        sqlite3_backup_step(copyConnection, -1)
        sqlite3_backup_finish(copyConnection)
        guard lastErrorCode == SQLITE_OK else {
            throw DatabaseError(database: self)
        }
    }
    
    private static func activateExtendedError(_ sqliteConnection: SQLiteConnection) throws {
        let code = sqlite3_extended_result_codes(sqliteConnection, 1)
        guard code == SQLITE_OK else {
            throw DatabaseError(code: code, message: String(cString: sqlite3_errmsg(sqliteConnection)))
        }
    }
    
    private static func openConnection(path: String, flags: Int32) throws -> SQLiteConnection {
        var sqliteConnection: SQLiteConnection? = nil
        let code = sqlite3_open_v2(path, &sqliteConnection, flags, nil)
        guard code == SQLITE_OK else {
            closeConnection(sqliteConnection)
            throw DatabaseError(code: code)
        }
        if let sqliteConnection = sqliteConnection {
            return sqliteConnection
        }
        throw DatabaseError(code: SQLITE_INTERNAL)
    }
    
    private static func closeConnection(_ sqliteConnection: SQLiteConnection?) {
        if #available(iOS 8.2, OSX 10.10, *) {
            sqlite3_close_v2(sqliteConnection)
        } else {
            sqlite3_close(sqliteConnection)
        }
    }
    
    func openConnection() throws {
        sqliteConnection = try Database.openConnection(path: storageLocation.path, flags: configuration.SQLiteOpenFlags)
        try setup()
    }
    
    func closeConnection() {
        Database.closeConnection(sqliteConnection)
    }
}

// MARK: Setup
extension Database {
    private func setup() throws {
        try setupEncryption()
        setupTrace()
        setupBusyMode()
        try Database.activateExtendedError(sqliteConnection)
        try setupForeignKey()
        try setupDefaultTable()
    }
    
    private func setupBusyMode() {
        switch configuration.busyMode {
        case .immediateError:
            break
        case .timeout(let duration):
            let milliseconds = Int32(duration * 1000)
            sqlite3_busy_timeout(sqliteConnection, milliseconds)
            
        case .callback(let callback):
            busyCallback = callback
            let dbPointer = Unmanaged.passUnretained(self).toOpaque()
            sqlite3_busy_handler(sqliteConnection, { dbPointer, numberOfTries in
                    let db = Unmanaged<Database>.fromOpaque(dbPointer!).takeUnretainedValue()
                    let callback = db.busyCallback!
                    return callback(Int(numberOfTries)) ? 1 : 0
            }, dbPointer)
        }
    }
    
    private func setupDefaultTable() throws {
        if configuration.readonly { return }
        if configuration.mapColumn  {
            let columnMap = VTDBConstants.Table.ColumnMap.self
            try create(table: columnMap.tableName, ifNotExists: true) { t in
                t.column(columnMap.Columns.tableName, .text).collate(.nocase)
                t.column(columnMap.Columns.columnName, .text).collate(.nocase)
                t.column(columnMap.Columns.columnType, .text).notNull().collate(.nocase)
                t.primaryKey(columnMap.Columns.tableName, columnMap.Columns.columnName)
            }
        }
        #if SQLEncrypted
        try encryption?.createTable(in: self)
        #endif
    }
    
    private func setupForeignKey() throws {
        if configuration.foreignKeysEnabled {
            try execute("PRAGMA foreign_keys = ON")
        }
    }
    
    private func setupEncryption() throws {
        #if SQLCipher
        if let key = configuration.key {
            switch key {
            case .passphrase(let string):
                try encrypt(with: string)
            case .rawKey(let data):
                try encrypt(with: data)
            }
            if let salt = configuration.salt {
                try setupPlainHeaderSizeAndSalt(salt)
            }
        }
        try validateSQLCipher()
        #endif
        #if SQLEncrypted
        switch configuration.encryptionType {
        case .none: return
        case .default:
            encryption = try Encryption()
        case .custom(let crypto, let storeKey):
            encryption = try Encryption(crypto: crypto, storeKey: storeKey)
        }
        try add(function: encryption!.encrypt)
        try add(function: encryption!.decrypt)
        #endif
    }
    
    #if SQLCipher
    private func setupPlainHeaderSizeAndSalt(_ salt: String) throws {
        try execute("PRAGMA cipher_plaintext_header_size = 32")
        try execute("PRAGMA cipher_salt = \"\(salt)\"")
    }
    
    private func validateSQLCipher() throws {
        // https://discuss.zetetic.net/t/important-advisory-sqlcipher-with-xcode-8-and-new-sdks/1688
        //
        // > In order to avoid situations where SQLite might be used
        // > improperly at runtime, we strongly recommend that
        // > applications institute a runtime test to ensure that the
        // > application is actually using SQLCipher on the active
        // > connection.
        if try String.fetchOne(self, sql: "PRAGMA cipher_version") == nil {
            throw DatabaseError(message: "VTDB is not linked against SQLCipher")
        }
    }
    #endif
    
    private func setupTrace() {
        guard configuration.trace != nil else {
            return
        }
        let dbPointer = Unmanaged.passUnretained(self).toOpaque()
        // sqlite3_trace_v2 and sqlite3_expanded_sql were introduced in SQLite 3.14.0 http://www.sqlite.org/changes.html#version_3_14
        
        if #available(iOS 10.0, OSX 10.12, watchOS 3.0, tvOS 10.0, *) {
            sqlite3_trace_v2(sqliteConnection, UInt32(SQLITE_TRACE_STMT), { (mask, dbPointer, stmt, unexpandedSQL) -> Int32 in
                guard let stmt = stmt else { return SQLITE_OK }
                guard let expandedSQLCString = sqlite3_expanded_sql(OpaquePointer(stmt)) else { return SQLITE_OK }
                let sql = String(cString: expandedSQLCString)
                sqlite3_free(expandedSQLCString)
                let db = Unmanaged<Database>.fromOpaque(dbPointer!).takeUnretainedValue()
                db.configuration.trace!(sql)
                return SQLITE_OK
            }, dbPointer)
        } else {
            sqlite3_trace(sqliteConnection, { (dbPointer, sql) in
                guard let sql = sql.map({ String(cString: $0) }) else { return }
                let db = Unmanaged<Database>.fromOpaque(dbPointer!).takeUnretainedValue()
                db.configuration.trace!(sql)
            }, dbPointer)
        }
    }
}

#if SQLCipher
// MARK: SQLCipher
extension Database {
    public func encrypt(with key: String) throws {
        if key.hasPrefix("x'") {
            guard key.hasSuffix("'") && (key.count == 64 + 3 || key.count == 96 + 3) else {
                throw VTDBError.invalidKey
            }
        }
        try execute("PRAGMA KEY = \"\(key)\"")
    }
    
    public func encrypt(with data: Data) throws {
        let hexString = data.hexadecimal
        try encrypt(with: "x'\(hexString)'")
    }
    
    public func export(to path: String, withKey key: String?, andSalt salt: String?) throws {
        if let key = key, key.hasPrefix("x'") {
            guard key.hasSuffix("'") && key.count == 64 + 3 else {
                throw VTDBError.invalidKey
            }
        }
        try execute("ATTACH DATABASE ? AS destinationDB KEY ?", path, key ?? "")
        if let salt = salt {
            guard salt.hasPrefix("x'") && salt.hasSuffix("'") && salt.count == 32 + 3 else {
                throw VTDBError.invalidSalt
            }
            try execute("PRAGMA destinationDB.cipher_plaintext_header_size = 32")
            try execute("PRAGMA destinationDB.cipher_salt = \"\(salt)\"")
        }
        try execute("SELECT sqlcipher_export('destinationDB')")
        try execute("DETACH DATABASE 'destinationDB'")
    }
    
    public func export(to path: String, withKey data: Data, andSalt salt: Data?) throws {
        let keyHex = data.hexadecimal
        if let saltHex = salt?.hexadecimal {
            try export(to: path, withKey: "x'\(keyHex)'", andSalt: "x'\(saltHex)'")
        } else {
            try export(to: path, withKey: "x'\(keyHex)'", andSalt: nil)
        }
    }
}
#endif

public extension Database {
    
    typealias BusyCallback = (_ numberOfTries: Int) -> Bool
    
    enum BusyMode {
        case immediateError
        case timeout(TimeInterval)
        case callback(BusyCallback)
    }
    
    enum CheckpointMode: Int32 {
        case passive = 0    // SQLITE_CHECKPOINT_PASSIVE
        case full = 1       // SQLITE_CHECKPOINT_FULL
        case restart = 2    // SQLITE_CHECKPOINT_RESTART
        case truncate = 3   // SQLITE_CHECKPOINT_TRUNCATE
    }
    
    enum Collation {
        case binary
        case rtrim
        case nocase
        case custom(String)
        
        var rawValue: String {
            switch self {
            case .binary: return "BINARY"
            case .rtrim: return "RTRIM"
            case .nocase: return "NOCASE"
            case .custom(let collation): return collation
            }
        }
    }
    
    enum ConflictResolution : String {
        case rollback = "ROLLBACK"
        case abort = "ABORT"
        case fail = "FAIL"
        case ignore = "IGNORE"
        case replace = "REPLACE"
    }
    
    enum ForeignKeyAction : String {
        case cascade = "CASCADE"
        case restrict = "RESTRICT"
        case setNull = "SET NULL"
        case setDefault = "SET DEFAULT"
    }
    
    enum TransactionCompletion {
        case commit
        case rollback
    }
    
    enum TransactionType : String {
        case deferred = "DEFERRED"
        case immediate = "IMMEDIATE"
        case exclusive = "EXCLUSIVE"
    }
}

extension Database {
    enum ThreadingMode {
        case `default`
        case multiThread
        case serialized
        
        var SQLiteOpenFlags: Int32 {
            switch self {
            case .default:
                return 0
            case .multiThread:
                return SQLITE_OPEN_NOMUTEX
            case .serialized:
                return SQLITE_OPEN_FULLMUTEX
            }
        }
    }
}

