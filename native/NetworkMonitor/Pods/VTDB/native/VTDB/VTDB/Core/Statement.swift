//
//  Statement.swift
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

public typealias SQLiteStatement = OpaquePointer
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public final class Statement {
    
    public let sqliteStatement: SQLiteStatement
    public unowned let database: Database
    public var parameters: [DatabaseValueConvertible?] = []
    public lazy var sql: SQL = {
        // trim white space and semicolumn for homogeneous output
        return String(cString: sqlite3_sql(sqliteStatement))
            .trimmingCharacters(in: CharacterSet(charactersIn: ";").union(.whitespacesAndNewlines))
    }()
    
    public init(database: Database, sql: String) throws {
        var sqliteStatement: SQLiteStatement?
        let code = sqlite3_prepare_v2(database.sqliteConnection, sql, -1, &sqliteStatement, nil)
        guard code == SQLITE_OK else {
            sqlite3_finalize(sqliteStatement)
            throw DatabaseError(database: database, sql: sql)
        }
        self.sqliteStatement = sqliteStatement!
        self.database = database
    }
    
    deinit {
        sqlite3_finalize(sqliteStatement)
    }
    
    func reset() throws {
        guard sqlite3_reset(sqliteStatement) == SQLITE_OK && sqlite3_clear_bindings(sqliteStatement) == SQLITE_OK else {
            throw DatabaseError(database: database, sql: sql)
        }
    }
    
    // MARK: Parameters
    lazy var sqliteParametersCount: Int = {
        Int(sqlite3_bind_parameter_count(self.sqliteStatement))
    }()
    
    // Returns ["id", nil", "name"] for "INSERT INTO table VALUES (:id, ?, :name)"
    private lazy var sqliteParametersNames: [String?] = {
        return (0..<self.sqliteParametersCount).map {
            guard let cString = sqlite3_bind_parameter_name(self.sqliteStatement, Int32($0 + 1)) else {
                return nil
            }
            return String(String(cString: cString).dropFirst()) // Drop initial ":", "@", "$"
        }
    }()
    
    // MARK: Columns
    /// The number of columns in the resulting rows.
    public lazy var columnCount: Int = {
        return Int(sqlite3_column_count(self.sqliteStatement))
    }()
    
    lazy var columnNames: [String] = {
        return (0..<self.columnCount).map { String(cString: sqlite3_column_name(self.sqliteStatement, Int32($0))) }
    }()
    
    lazy var columnIndexes: [String: Int] = {
        let dict = Dictionary(
            self.columnNames
                .enumerated()
                .map { ($0.element.lowercased(), $0.offset) },
            uniquingKeysWith: { (left, _) in left }) // keep leftmost indexes
        return dict
    }()
    
    func column(name index: Int) -> String {
        return columnNames[index]
    }
    
    func column(index name: String) -> Int? {
        if let index = columnIndexes[name] {
            return index
        }
        return columnIndexes[name.lowercased()]
    }
    
    //MARK: Bind Parameters
    @discardableResult
    public func bind(_ parameters: DatabaseValueConvertible?...) throws -> Statement {
        try bind(parameters)
        return self
    }
    
    @discardableResult
    public func bind(_ parameters: [DatabaseValueConvertible?]) throws -> Statement {
        try reset()
        self.parameters = parameters
        let parametersCount = sqliteParametersCount
        guard parametersCount == parameters.count else {
            throw DatabaseError(code: SQLITE_RANGE, message: "Bind expected \(parametersCount) parameters, instead received \(parameters.count)", sql: sql, parameters: parameters)
        }
        
        for (index, parameter) in parameters.enumerated() {
            try bind(parameter, atIndex: Int32(index + 1))
        }
        return self
    }
    
    @discardableResult
    public func bind(_ parameters: [String: DatabaseValueConvertible?]) throws -> Statement {
        try reset()
        self.parameters = parameters.allValues
        let parametersCount = sqliteParametersCount
        guard parametersCount == parameters.count else {
            throw DatabaseError(code: SQLITE_RANGE, message: "Bind expected \(parametersCount) parameters, instead received \(parameters.count)", sql: sql)
        }
        
        for (key, parameter) in parameters {
            let index = Int32(sqlite3_bind_parameter_index(sqliteStatement, key))
            guard index > 0 else {
                throw DatabaseError(code: SQLITE_ERROR, message: "Bind could not find index for key: '\(key)'", sql: sql)
            }
            try bind(parameter, atIndex: index)
        }
        
        return self
    }
    
    private func bind(_ parameter: DatabaseValueConvertible?, atIndex index: Int32) throws {
        let code: Int32
        if let parameter = parameter {
            switch parameter.databaseValue {
            case .null:
                code = sqlite3_bind_null(sqliteStatement, index)
            case .integer(let int64):
                code = sqlite3_bind_int64(sqliteStatement, index, int64)
            case .real(let double):
                code = sqlite3_bind_double(sqliteStatement, index, double)
            case .text(let string):
                code = sqlite3_bind_text(sqliteStatement, index, string, -1, SQLITE_TRANSIENT)
            case .blob(let data):
                code = data.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(sqliteStatement, index, bytes, Int32(data.count), SQLITE_TRANSIENT)
                }
            }
        } else {
            code = sqlite3_bind_null(sqliteStatement, index)
        }
        guard code == SQLITE_OK else {
            throw DatabaseError(code: code, message: database.lastErrorMessage, sql: sql)
        }
    }
    
    // MARK: Step
    @discardableResult
    func step() throws -> Bool {
        let code = sqlite3_step(sqliteStatement)
        guard code == SQLITE_ROW || code == SQLITE_DONE else {
            throw DatabaseError(code: code, message: database.lastErrorMessage, sql: sql, parameters: parameters)
        }
        return code == SQLITE_ROW
    }
    
    public func run() throws {
        while try step() {}
//        reset()
        database.databaseObserver?.statementReset = true
    }
    
    func value(at index: Int) -> Any? {
        let index = Int32(index)
        switch sqlite3_column_type(sqliteStatement, index) {
        case SQLITE_NULL:
            return nil
        case SQLITE_INTEGER:
            return NSNumber(value: sqlite3_column_int64(sqliteStatement, index))
        case SQLITE_FLOAT:
            return sqlite3_column_double(sqliteStatement, index)
        case SQLITE_TEXT:
            return String(cString: sqlite3_column_text(sqliteStatement, index))
        case SQLITE_BLOB:
            guard let bytes = sqlite3_column_blob(sqliteStatement, index) else {
                return nil
            }
            let count = Int(sqlite3_column_bytes(sqliteStatement, index))
            return Data(bytes: bytes, count: count)
        case let type:
            // Assume a bug: there is no point throwing any error.
            debugPrint("Unexpected SQLite column type: \(type)")
            return nil
        }
    }
    
    func mappedValue(at index: Int, of type: Database.ColumnType) throws -> Any? {
        guard let int32 = Int32(exactly: index) else {
            return VTDBError.getCastError(actualType: Int.self, expectedType: Int32.self)
        }
        if sqlite3_column_type(sqliteStatement, int32) == SQLITE_NULL {
            return nil
        }
        switch type {
        case .int, .integer: return try Int(sqliteStatement: sqliteStatement, index: int32)
        case .int8: return try Int8(sqliteStatement: sqliteStatement, index: int32)
        case .int16: return try Int16(sqliteStatement: sqliteStatement, index: int32)
        case .int32: return try Int32(sqliteStatement: sqliteStatement, index: int32)
        case .int64: return try Int64(sqliteStatement: sqliteStatement, index: int32)
        case .uint: return try UInt(sqliteStatement: sqliteStatement, index: int32)
        case .uint8: return try UInt8(sqliteStatement: sqliteStatement, index: int32)
        case .uint16: return try UInt16(sqliteStatement: sqliteStatement, index: int32)
        case .uint32: return try UInt32(sqliteStatement: sqliteStatement, index: int32)
        case .uint64: return try UInt64(sqliteStatement: sqliteStatement, index: int32)
        case .bool: return try Bool(sqliteStatement: sqliteStatement, index: int32)
        case .double, .real: return try Double(sqliteStatement: sqliteStatement, index: int32)
        case .float: return try Float(sqliteStatement: sqliteStatement, index: int32)
        case .data, .blob: return try Data(sqliteStatement: sqliteStatement, index: int32)
        case .text, .string: return try String(sqliteStatement: sqliteStatement, index: int32)
        case .character: return try Character(sqliteStatement: sqliteStatement, index: int32)
        case .date: return Date.fromDatabaseValue(value(at: index) as Any)
        case .url: return URL.fromDatabaseValue(value(at: index) as Any)
        }
    }
    
    public func value<T: DatabaseValueConvertible & StatementColumnConvertible>(at index: Int) throws -> T? {
        guard sqlite3_column_type(sqliteStatement, Int32(index)) != SQLITE_NULL else {
            return nil
        }
        return try T.init(sqliteStatement: sqliteStatement, index: Int32(index))
    }
    
    public func value<T: DatabaseValueConvertible & StatementColumnConvertible>(forColumnName columnName: String) throws -> T? {
        guard let index = column(index: columnName) else { return nil }
        return try value(at: index)
    }
    
    public func value<T: DatabaseValueConvertible>(at columnIndex: Int) -> T? {
        guard let dbValue = self.value(at: columnIndex) else { return nil }
        return T.fromDatabaseValue(dbValue)
    }
    
    public func value<T: DatabaseValueConvertible>(forColumnName columnName: String) -> T? {
        guard let index = column(index: columnName) else { return nil }
        guard let dbValue = self.value(at: index) else { return nil }
        return T.fromDatabaseValue(dbValue)
    }
    
    // MARK: Query
    //Todo: Needs to be updated
    public func query<T: DatabaseValueConvertible & StatementColumnConvertible>() throws -> T? {
        try step()
        return try value(at: 0)
    }
    
    public func query<T: DatabaseValueConvertible & StatementColumnConvertible>() throws -> T {
        try step()
        return try value(at: 0)!
    }
    
    public func query<T: DatabaseValueConvertible>() throws -> T? {
        try step()
        return value(at: 0)
    }
    
    public func query<T: DatabaseValueConvertible>() throws -> T {
        try step()
        return value(at: 0)!
    }
    
    public func query<T: DatabaseValueConvertible & StatementColumnConvertible>() throws -> [T?] {
        var values = [T?]()
        while try step() {
            values.append(try value(at: 0))
        }
        return values
    }
    
    public func query<T: DatabaseValueConvertible & StatementColumnConvertible>() throws -> [T] {
        var values = [T]()
        while try step() {
            values.append(try value(at: 0)!)
        }
        return values
    }
    
    public func query<T: DatabaseValueConvertible>() throws -> [T?] {
        var values = [T?]()
        while try step() {
            values.append(value(at: 0))
        }
        return values
    }
    
    public func query<T: DatabaseValueConvertible>() throws -> [T] {
        var values = [T]()
        while try step() {
            values.append(value(at: 0)!)
        }
        return values
    }
    
    public func query(columnType: [String: Database.ColumnType]) throws -> [[String: Any]] {
        var records = [[String: Any]]()
        let columnTypes = columnNames.map { columnType[$0.lowercased()] }
        while try step() {
            var dict: [String: Any] = [:]
            for (index, type) in columnTypes.enumerated() {
                if let type = type {
                    dict.updateValue(try mappedValue(at: index, of: type) as Any, forKey: columnNames[index])
                } else {
                    dict.updateValue(value(at: index) as Any, forKey: columnNames[index])
                }
            }
            records.append(dict)
        }
        return records
    }
    
    public func queryDict(columnType: [String: Database.ColumnType]) throws -> [[String: Any?]] {
        var records = [[String: Any?]]()
        let columnTypes = columnNames.map { columnType[$0.lowercased()] }
        while try step() {
            var dict: [String: Any?] = [:]
            for (index, type) in columnTypes.enumerated() {
                if let type = type {
                    dict.updateValue(try mappedValue(at: index, of: type), forKey: columnNames[index])
                } else {
                    dict.updateValue(value(at: index), forKey: columnNames[index])
                }
            }
            records.append(dict)
        }
        return records
    }
    
    
    public func query<T: Equatable & Hashable>(columnType: [String: Database.ColumnType], groupBy field: String) throws -> [Section<T>] {
        var ungroupped: Section<T> = Section(group: nil, items: [])
        var sections: [Section<T>] = []
        var sectionIndex: [T: Int] = [:]
        let columnTypes = columnNames.map { columnType[$0.lowercased()] }
        while try step() {
            var dict: [String: Any] = [:]
            for (index, type) in columnTypes.enumerated() {
                if let type = type {
                    dict.updateValue(try mappedValue(at: index, of: type) as Any, forKey: columnNames[index])
                } else {
                    dict.updateValue(value(at: index) as Any, forKey: columnNames[index])
                }
            }
            
            if let element = dict[field] as? T {
                if let index = sectionIndex[element] {
                    sections[index].items.append(dict)
                } else {
                    sectionIndex[element] = sections.count
                    sections.append(Section(group: element, items: [dict]))
                }
            } else {
                ungroupped.items.append(dict)
            }
        }
        if !ungroupped.items.isEmpty {
            sections.insert(ungroupped, at: 0)
        }
        return sections
    }
    
    public func query() throws -> [[String: Any]] {
        var columnType: [String: Database.ColumnType] = [:]
        if database.configuration.mapColumn {
            columnType = try database.columnTypes(fromSQL: sql)
        }
        if columnType.isEmpty {
            var records = [[String: Any]]()
            while try step() {
                records.append(Dictionary(
                    columnNames.enumerated().map {
                        ($0.element, value(at: $0.offset) as Any)
                    }, uniquingKeysWith: { (left, _) in left })
                )
            }
            return records
        } else {
            return try query(columnType: columnType)
        }
    }
    
    public func queryDict() throws -> [[String: Any?]] {
        var columnType: [String: Database.ColumnType] = [:]
        if database.configuration.mapColumn {
            columnType = try database.columnTypes(fromSQL: sql)
        }
        if columnType.isEmpty {
            var records = [[String: Any?]]()
            while try step() {
                records.append(Dictionary(
                    columnNames.enumerated().map {
                        ($0.element, value(at: $0.offset))
                    }, uniquingKeysWith: { (left, _) in left })
                )
            }
            return records
        } else {
            return try queryDict(columnType: columnType)
        }
    }
    
    public func query<T: Equatable & Hashable>(groupBy field: String) throws -> [Section<T>] {
        var columnType: [String: Database.ColumnType] = [:]
        if database.configuration.mapColumn {
            columnType = try database.columnTypes(fromSQL: sql)
        }
        var ungroupped: Section<T> = Section(group: nil, items: [])
        var sections: [Section<T>] = []
        var sectionIndex: [T: Int] = [:]
        var ungroupIndex = -1
        if columnType.isEmpty {
            while try step() {
                let dict = Dictionary(
                    columnNames.enumerated().map {
                        ($0.element, value(at: $0.offset) as Any)
                }, uniquingKeysWith: { (left, _) in left })
                
                if let element = dict[field] as? T {
                    if let index = sectionIndex[element] {
                        sections[index].items.append(dict)
                    } else {
                        sectionIndex[element] = sections.count
                        sections.append(Section(group: element, items: [dict]))
                    }
                } else {
                    if ungroupIndex == -1 {
                        ungroupIndex = sections.count
                    }
                    ungroupped.items.append(dict)
                }
            }
            if !ungroupped.items.isEmpty && ungroupIndex != -1 {
                sections.insert(ungroupped, at: ungroupIndex)
            }
            return sections
        } else {
            return try query(columnType: columnType, groupBy: field)
        }
    }
    
    public func query<T: RowConvertible>() throws -> T {
        try step()
        let row = Row(statement: self, columnIndexes: columnIndexes)
        return try T(row: row)
    }
    
    public func query<T: RowConvertible>() throws -> [T] {
        var records = [T] ()
        let row = Row(statement: self)
        
        while try step() {
            let record = try T(row: row)
            records.append(record)
        }
        return records
    }
    
    public func query<T: Row>() throws -> T {
        try step()
        let row = T(statement: self, columnIndexes: columnIndexes)
        return row
    }
    
    public func query<T: Row>() throws -> [T] {
        var rows: [T] = []
        let row = T(statement: self)
        while try step() {
            rows.append(row.copy())
        }
        return rows
    }
    
    public func query<T: Any>() throws -> [[T]] {
        var rows = [[T]]()
        while try step() {
            var values: [Any] = []
            for index in 0..<columnCount {
                values.append(value(at: index) as Any)
            }
            rows.append(values as! [T])
        }
        return rows
    }
}
