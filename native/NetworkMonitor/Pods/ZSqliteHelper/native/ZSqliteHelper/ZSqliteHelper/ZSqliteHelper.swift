//
//  ZSqliteHelper.swift
//  ZohoMail
//
//  Created by Rahul T on 26/07/17.
//  Copyright © 2017 Zoho Corporation. All rights reserved.
//

import Foundation
import VTDB

public struct ZColumnType {

    public static let text     = "TEXT"
    public static let number   = "NUMBER"
    public static let integer  = "INTEGER"
    public static let blob     = "BLOB"
    public static let boolean  = "BOOLEAN"
    public static let date     = "DATE"
    public static let dateTime = "DATETIME"
    public static let unique   = "UNIQUE"
}

public enum ZSqlConflictResolution: String {
    case rollback = "ROLLBACK"
    case abort = "ABORT"
    case fail = "FAIL"
    case ignore = "IGNORE"
    case replace = "REPLACE"
}

public enum ZSqliteConnectionMode {
    case pool
    case queue
}

public enum ZSqliteBusyMode {
    case immediateError
    case timeout(TimeInterval)
    case callback((_ numberOfTries: Int) -> Bool)
}

public class ZSqliteConfiguration {

    public var dbPath: String
    public var connectionMode: ZSqliteConnectionMode
    public var readOnlyMode: Bool = false
    public var busyMode: ZSqliteBusyMode = ZSqliteBusyMode.immediateError
    public var trace: TraceFunction?

    public init(connectionMode: ZSqliteConnectionMode, dbPath: String) {
        self.connectionMode = connectionMode
        self.dbPath = dbPath
    }
}

class ZSqlitePersistance {

    var database: VTDatabase?
    var configuration: ZSqliteConfiguration

    init(configuration: ZSqliteConfiguration) {
        self.configuration = configuration
        var configuration = Configuration()
        switch self.configuration.busyMode {
        case .immediateError:
            configuration.busyMode = Database.BusyMode.immediateError
        case .timeout(let timeInterval):
            configuration.busyMode = Database.BusyMode.timeout(timeInterval)
        case .callback(let block):
            configuration.busyMode = Database.BusyMode.callback(block)
        }
        configuration.readonly = self.configuration.readOnlyMode
        configuration.trace = self.configuration.trace

        do {
            switch self.configuration.connectionMode {
            case .pool:
                database = try DatabasePool(path: self.configuration.dbPath, configuration: configuration)
            case .queue:
                database = try DatabaseQueue(path: self.configuration.dbPath, configuration: configuration)
            }
        } catch {
            ZSqliteHelper.getShared().dlog("error: \(error)")
        }
    }
}

enum ZMDBError: Error {

    case dbSelectQueryError(queryObj: [String: Any?])
}

//NOTE:- All the modules and frameworks using this class has to adopt to ZSqliteHelper new function with identifier and remove this old functions from the pod
public class ZSqliteHelper: NSObject {

    private static var shared: ZSqliteHelper?
    fileprivate let defaultDBIdentifier = "DefaultDB"

    public static func getShared() -> ZSqliteHelper {
        if shared == nil {
            shared = ZSqliteHelper()
        }
        return shared!
    }

    var databaseDict: [String: ZSqlitePersistance] = [String: ZSqlitePersistance]()

    public func createDB() {

    }

    public func closeDB() {

    }
}

// MARK: - Public methods

extension ZSqliteHelper {

    public func registerDB(configuration: ZSqliteConfiguration) {
        registerDB(identifier: defaultDBIdentifier, configuration: configuration)
    }

    public func deregisterDB() {
        deregisterDB(identifier: defaultDBIdentifier)
    }

    public func attachDB(path: String, name: String) {
        attachDB(path: path, name: name, on: defaultDBIdentifier)
    }

    public func detachDB(name: String) {
        detachDB(name: name, on: defaultDBIdentifier)
    }

    public func drop(tableName: String, ifExists: Bool = true, alert: Bool = true) {
        drop(tableName: tableName, ifExists: ifExists, alert: alert, identifier: defaultDBIdentifier)
    }

    public func select(_ rawQuery: String, alert: Bool = true) -> [Any]? {
        return select(rawQuery, alert: alert, identifier: defaultDBIdentifier)
    }

    public func save(tableName: String, columnData: [String: Any], replace: Bool = true, alert: Bool = true) {
        save(tableName: tableName, columnData: columnData, replace: replace, alert: alert, identifier: defaultDBIdentifier)
    }

    public func save(columns: [[String: Any]], in tableName: String, replace: Bool = true, alert: Bool = true) {
        save(tableName: tableName, columns: columns, replace: replace, alert: alert, identifier: defaultDBIdentifier)
    }

    public func select(from tableName: String, sortDescriptor:(columnName: String, isAcending: Bool)?,
                              where criteria: String?, limit noOfRecordsToFetch: Int? = nil, offset: Int? = nil, alert: Bool = true) -> [Any]? {
        return select(from: tableName, sortDescriptor: sortDescriptor, where: criteria, limit: noOfRecordsToFetch, offset: offset, alert: alert, identifier: defaultDBIdentifier)
    }

    public func execute(rawQuery: String, alert: Bool = true) {
        execute(rawQuery: rawQuery, alert: alert, identifier: defaultDBIdentifier)
    }

    public func execute(rawQueries: [String], alert: Bool = true) {
        execute(rawQueries: rawQueries, alert: alert, identifier: defaultDBIdentifier)
    }

    public func delete(from tableName: String, where criteria: String?, alert: Bool = true) {
        delete(from: tableName, where: criteria, alert: alert, identifier: defaultDBIdentifier)
    }

    public func update(tableName: String, where criteria: String?, columnData: [String: Any], onConflict conflictResolution: ZSqlConflictResolution? = nil, alert: Bool = true) {
        update(tableName: tableName, where: criteria, columnData: columnData, onConflict: conflictResolution, alert: alert, identifier: defaultDBIdentifier)
    }
}

// MARK: - New methods

// MARK: - Public methods

extension ZSqliteHelper {

    public func registerDB(identifier: String, configuration: ZSqliteConfiguration) {
        if databaseDict[identifier] == nil {
            let persistance = ZSqlitePersistance(configuration: configuration)
            databaseDict[identifier] = persistance
        } else {
            dlog("Already registed identifier: \(identifier) path:\(configuration.dbPath)", alert: false)
        }
    }

    public func deregisterDB(identifier: String) {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(identifier)")
            return
        }
        db.releaseMemory()
        databaseDict.removeValue(forKey: identifier)
    }

    public func attachDB(path: String, name: String, on identifier: String) {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(identifier)")
            return
        }
        do {
            try db.attachDatabase(fromPath: path, withName: name)
        } catch {
            dlog("error: \(error)")
        }

    }

    public func detachDB(name: String, on identifier: String) {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(identifier)")
            return
        }
        do {
            try db.detachDatabase(named: name)
        } catch {
            dlog("error: \(error)")
        }
    }

    public func drop(tableName: String, ifExists: Bool = true, alert: Bool = true, identifier: String?) {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(String(describing: identifier))")
            return
        }
        do {
            try db.write({ db in
                try db.drop(table: tableName, ifExists: ifExists)
            })
        } catch {
            dlog("error: \(error)", alert: alert)
        }
    }

    public func select(_ rawQuery: String, alert: Bool = true, identifier: String?) -> [Any]? {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(String(describing: identifier))")
            return nil
        }
        do {
            return try db.read { db in
                try db.query(rawQuery)
            }
        } catch {
            dlog("error: \(error)", alert: alert)
        }
        return nil
    }

    public func save(tableName: String, columnData: [String: Any], replace: Bool = true, alert: Bool = true, identifier: String?) {
        save(tableName: tableName, columns: [columnData], replace: replace, alert: alert, identifier: identifier)
    }

    public func save(tableName: String, columns: [[String: Any]], replace: Bool = true, alert: Bool = true, identifier: String?) {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(String(describing: identifier))")
            return
        }
        do {
            try db.writeInTransaction { db in
                for columnData in columns {
                    try db.insert(intoTable: tableName, values: columnData, onConflict: replace ? .replace : nil)
                }
                return .commit
            }
        } catch {
            dlog("error: \(error)", alert: alert)
        }
    }

    public func select(from tableName: String, sortDescriptor:(columnName: String, isAcending: Bool)?,
                       where criteria: String?, limit noOfRecordsToFetch: Int? = nil, offset: Int? = nil, alert: Bool = true, identifier: String?) -> [Any]? {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(String(describing: identifier))")
            return nil
        }
        do {
            var query = SelectQuery(table: tableName)
            if let criteria = criteria {
                query = query.filter(criteria)
            }
            if let sortDescriptor = sortDescriptor {
                let expression = SQLOrderExpression(sortDescriptor.isAcending ? SQLOrder.asc : SQLOrder.desc, expression: sortDescriptor.columnName)
                query.order(expression)
            }
            if noOfRecordsToFetch != nil && offset != nil {
                query = query.limit(noOfRecordsToFetch!, offset: offset!)
            }
            return try db.read { db in
                try query.fetchAll(db)
            }
        } catch {
            dlog("error: \(error)", alert: alert)
        }
        return nil
    }

    public func execute(rawQuery: String, alert: Bool = true, identifier: String?) {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(String(describing: identifier))")
            return
        }
        do {
            try db.writeInTransaction { db in
                try db.execute(rawQuery)
                return .commit
            }
        } catch {
            dlog("error: \(error)", alert: alert)
        }
    }

    public func execute(rawQueries: [String], alert: Bool = true, identifier: String?) {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(String(describing: identifier))")
            return
        }
        do {
            try db.writeInTransaction { db in
                for rawQuery in rawQueries {
                    try db.execute(rawQuery)
                }
                return .commit
            }
        } catch {
            dlog("error: \(error)", alert: alert)
        }
    }

    public func delete(from tableName: String, where criteria: String?, alert: Bool = true, identifier: String?) {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(String(describing: identifier))")
            return
        }
        do {
            try db.write { db in
                try db.delete(fromTable: tableName, where: criteria)
            }
        } catch {
            dlog("error: \(error)", alert: alert)
        }
    }

    public func update(tableName: String, where criteria: String?, columnData: [String: Any], onConflict conflictResolution: ZSqlConflictResolution? = nil, alert: Bool = true, identifier: String?) {
        guard let db = getDB(identifier: identifier) else {
            dlog("DB not found: \(String(describing: identifier))")
            return
        }
        var conflict: Database.ConflictResolution?
        if conflictResolution != nil {
            conflict = getVTConflictResolution(resolution: conflictResolution!)
        }
        do {
            try db.write { db in
                try db.update(table: tableName, with: columnData, where: criteria, onConflict: conflict)
            }
        } catch {
            dlog("error: \(error)", alert: alert)
        }
    }
}

// MARK: - Helpers

extension ZSqliteHelper {

    func getDB(identifier: String?) -> VTDatabase? {
        let identifier = identifier ?? defaultDBIdentifier
        return databaseDict[identifier]?.database
    }

    func getVTConflictResolution(resolution: ZSqlConflictResolution) -> Database.ConflictResolution? {
        switch resolution {
        case .abort:
            return Database.ConflictResolution.abort
        case .fail:
            return Database.ConflictResolution.fail
        case .ignore:
            return Database.ConflictResolution.ignore
        case .replace:
            return Database.ConflictResolution.replace
        case .rollback:
            return Database.ConflictResolution.rollback
        }
    }

    func dlog(_ items: Any..., tag: String = "", function: StaticString = #function, line: UInt = #line, alert: Bool = true) {
        #if DEBUG
            let log = "\(function) [Line \(line)]: \(tag) \(items)"
            print(log)
            if alert {
                assert(false, log)
            }
        #endif
    }
}
