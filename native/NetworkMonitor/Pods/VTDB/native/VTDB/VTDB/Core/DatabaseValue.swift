//
//  DatabaseValue.swift
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

public enum DatabaseValue {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)
}

extension DatabaseValue {
    init(sqliteStatement: SQLiteStatement, index: Int32) {
        switch sqlite3_column_type(sqliteStatement, index) {
        case SQLITE_INTEGER:
            self = .integer(sqlite3_column_int64(sqliteStatement, index))
        case SQLITE_FLOAT:
            self = .real(sqlite3_column_double(sqliteStatement, index))
        case SQLITE_TEXT:
            self = .text(String(cString: sqlite3_column_text(sqliteStatement, index)))
        case SQLITE_BLOB:
            if let bytes = sqlite3_column_blob(sqliteStatement, Int32(index)) {
                let count = Int(sqlite3_column_bytes(sqliteStatement, Int32(index)))
                self = .blob(Data(bytes: bytes, count: count))
            } else {
                self = .null
            }
        default:
            self = .null
        }
    }
    
    init(sqliteValue: OpaquePointer) {
        switch sqlite3_value_type(sqliteValue) {
        case SQLITE_INTEGER:
            self = .integer(sqlite3_value_int64(sqliteValue))
        case SQLITE_FLOAT:
            self = .real(sqlite3_value_double(sqliteValue))
        case SQLITE_TEXT:
            self = .text(String(cString: sqlite3_value_text(sqliteValue)))
        case SQLITE_BLOB:
            if let bytes = sqlite3_value_blob(sqliteValue) {
                let count = Int(sqlite3_value_bytes(sqliteValue))
                self = .blob(Data(bytes: bytes, count: count))
            } else {
                self = .null
            }
        default:
            self = .null
        }
    }
}

extension DatabaseValue: Equatable {
    public static func ==(lhs: DatabaseValue, rhs: DatabaseValue) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null): return true
        case let (.integer(lhsValue), .integer(rhsValue)): return lhsValue == rhsValue
        case let (.real(lhsValue), .real(rhsValue)): return lhsValue == rhsValue
        case let (.text(lhsValue), .text(rhsValue)): return lhsValue == rhsValue
        case let (.blob(lhsValue), .blob(rhsValue)): return lhsValue == rhsValue
        default: return false
        }
    }
}

extension DatabaseValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null:
            return "nil"
        case .integer(let int64):
            return String(describing: int64)
        case .real(let double):
            return String(describing: double)
        case .text(let string):
            return string
        case .blob(let data):
            return String(describing: data)
        }
    }
}

public protocol DatabaseValueConvertible: SQLExpression, SQLRawExpression {
    var databaseValue: DatabaseValue { get }
    
    static func fromDatabaseValue(_ dbValue: Any) -> Self?
    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self?
}

extension DatabaseValueConvertible {
    public var rawExpression: String {
        return String(describing: self)
    }
    
    public var parameters: [DatabaseValueConvertible?] {
        return [self]
    }
    #if SQLEncrypted
    public func expressionSQL(_ db: Database, encryptedColumns: Set<String>) -> String {
        return rawExpression
    }
    #else
    public var expressionSQL: String {
        return rawExpression
    }
    #endif
}

// MARK: Integer Value
extension Bool: DatabaseValueConvertible, StatementColumnConvertible {
    
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        let string = String(cString: sqlite3_column_text(sqliteStatement, index))
        self = string == "1" || string.lowercased() == "true"
    }
    
    public var databaseValue: DatabaseValue { return .integer(Int64(self ? 1 : 0)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Bool? {
        return Int64.fromDatabaseValue(dbValue).flatMap { $0 == 1 }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Bool? {
        if let int64  = Int64.fromDatabaseValue(dbValue) {
            return int64 == 1
        } else if let string = String.fromDatabaseValue(dbValue) {
            return string.lowercased() == "true"
        }
        return nil
    }
    
    public var expressionSQL: String {
        return self ? "1" : "0"
    }
}

extension Int: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        guard let value = Int(exactly: sqlite3_column_int64(sqliteStatement, index)) else {
            throw VTDBError.getCastError(actualType: Int64.self, expectedType: Int.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .integer(Int64(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Int? {
        return Int64.fromDatabaseValue(dbValue).flatMap { Int(exactly: $0) }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Int? {
        return Int64.fromDatabaseValue(dbValue).flatMap { Int(exactly: $0) }
    }
}

extension Int8: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        guard let value = Int8(exactly: sqlite3_column_int64(sqliteStatement, index)) else {
            throw VTDBError.getCastError(actualType: Int64.self, expectedType: Int8.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .integer(Int64(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Int8? {
        return Int64.fromDatabaseValue(dbValue).flatMap { Int8(exactly: $0) }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Int8? {
        return Int64.fromDatabaseValue(dbValue).flatMap { Int8(exactly: $0) }
    }
}

extension Int16: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        guard let value = Int16(exactly: sqlite3_column_int64(sqliteStatement, index)) else {
            throw VTDBError.getCastError(actualType: Int64.self, expectedType: Int16.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .integer(Int64(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Int16? {
        return Int64.fromDatabaseValue(dbValue).flatMap { Int16(exactly: $0) }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Int16? {
        return Int64.fromDatabaseValue(dbValue).flatMap { Int16(exactly: $0) }
    }
}

extension Int32: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        guard let value = Int32(exactly: sqlite3_column_int64(sqliteStatement, index)) else {
            throw VTDBError.getCastError(actualType: Int64.self, expectedType: Int32.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .integer(Int64(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Int32? {
        return Int64.fromDatabaseValue(dbValue).flatMap { Int32(exactly: $0) }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Int32? {
        return Int64.fromDatabaseValue(dbValue).flatMap { Int32(exactly: $0) }
    }
}

extension Int64: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        self = sqlite3_column_int64(sqliteStatement, index)
    }
    
    public var databaseValue: DatabaseValue { return .integer(self) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Int64? {
        switch dbValue {
        case let int64 as Int64: return int64
        case let int as Int: return Int64(int)
        case let double as Double: return Int64(exactly: double)
        default: return nil
        }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Int64? {
        switch dbValue {
        case .integer(let int64):
            return int64
        case .real(let double):
            return Int64(exactly: double)
        default:
            return nil
        }
    }
}

extension UInt: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        let string = String(cString: sqlite3_column_text(sqliteStatement, index))
        guard let value = UInt(string) else {
            throw VTDBError.getCastError(actualType: String.self, expectedType: UInt.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .text(String(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> UInt? {
        return UInt64.fromDatabaseValue(dbValue).flatMap { UInt(exactly: $0) }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> UInt? {
        return UInt64.fromDatabaseValue(dbValue).flatMap { UInt(exactly: $0) }
    }
}

extension UInt8: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        let string = String(cString: sqlite3_column_text(sqliteStatement, index))
        guard let value = UInt8(string) else {
            throw VTDBError.getCastError(actualType: String.self, expectedType: UInt8.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .text(String(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> UInt8? {
        return UInt64.fromDatabaseValue(dbValue).flatMap { UInt8(exactly: $0) }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> UInt8? {
        return UInt64.fromDatabaseValue(dbValue).flatMap { UInt8(exactly: $0) }
    }
}

extension UInt16: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        let string = String(cString: sqlite3_column_text(sqliteStatement, index))
        guard let value = UInt16(string) else {
            throw VTDBError.getCastError(actualType: String.self, expectedType: UInt16.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .text(String(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> UInt16? {
        return UInt64.fromDatabaseValue(dbValue).flatMap { UInt16(exactly: $0) }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> UInt16? {
        return UInt64.fromDatabaseValue(dbValue).flatMap { UInt16(exactly: $0) }
    }
}

extension UInt32: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        let string = String(cString: sqlite3_column_text(sqliteStatement, index))
        guard let value = UInt32(string) else {
            throw VTDBError.getCastError(actualType: String.self, expectedType: UInt32.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .text(String(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> UInt32? {
        return UInt64.fromDatabaseValue(dbValue).flatMap { UInt32(exactly: $0) }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> UInt32? {
        return UInt64.fromDatabaseValue(dbValue).flatMap { UInt32(exactly: $0) }
    }
}

extension UInt64: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        let string = String(cString: sqlite3_column_text(sqliteStatement, index))
        guard let value = UInt64(string) else {
            throw VTDBError.getCastError(actualType: String.self, expectedType: UInt64.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .text(String(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> UInt64? {
        switch dbValue {
        case let int64 as Int64: return UInt64(exactly: int64)
        case let int as Int: return UInt64(exactly: int)
        case let double as Double: return UInt64(exactly: double)
        case let string as String: return UInt64(string)
        default: return nil
        }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> UInt64? {
        switch dbValue {
        case .integer(let int64):
            return UInt64(exactly: int64)
        case .real(let double):
            return UInt64(exactly: double)
        case .text(let string):
            return UInt64(string)
        default:
            return nil
        }
    }
}

// MARK: Real Value
extension Double: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        self = sqlite3_column_double(sqliteStatement, index)
    }
    
    public var databaseValue: DatabaseValue{ return .real(Double(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Double? {
        switch dbValue {
        case let int64 as Int64: return Double(int64)
        case let int as Int: return Double(int)
        case let string as String: return Double(string)
        default: return dbValue as? Double
        }
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Double? {
        switch dbValue {
        case .integer(let int64):
            return Double(exactly: int64)
        case .real(let double):
            return double
        case .text(let string):
            return Double(string)
        default:
            return nil
        }
    }
}

extension Float: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        guard let value = Float(exactly: sqlite3_column_double(sqliteStatement, index)) else {
            throw VTDBError.getCastError(actualType: Double.self, expectedType: Float.self)
        }
        self = value
    }
    
    public var databaseValue: DatabaseValue { return .real(Double(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Float? {
        if let double = Double.fromDatabaseValue(dbValue) {
            return Float(exactly: double)
        }
        return nil
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Float? {
        if let double = Double.fromDatabaseValue(dbValue) {
            return Float(exactly: double)
        }
        return nil
    }
}

// MARK: Text Value
extension Character: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        self = Character(String(cString: sqlite3_column_text(sqliteStatement, index)))
    }
    
    public var databaseValue: DatabaseValue { return .text(String(self)) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Character? {
        if let string = String.fromDatabaseValue(dbValue) {
            return Character(string)
        }
        return nil
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Character? {
        if let string = String.fromDatabaseValue(dbValue) {
            return Character(string)
        }
        return nil
    }
    
    
}

extension String: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        self = String(cString: sqlite3_column_text(sqliteStatement, index))
    }
    
    public var databaseValue: DatabaseValue{ return .text(self) }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> String? {
        return dbValue as? String
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> String? {
        switch dbValue {
        case .integer(let int64):
            return String(int64)
        case .real(let double):
            return String(double)
        case .text(let string):
            return string
        default:
            return nil
        }
    }
}

// MARK: Date
extension Date: DatabaseValueConvertible {
    
    public var databaseValue: DatabaseValue {
        return .real(self.timeIntervalSince1970)
        // return .text(dateFormatter.string(from: self))
    }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Date? {
        if let double = Double.fromDatabaseValue(dbValue) {
            return Date(timeIntervalSince1970: double)
        } else if let string = String.fromDatabaseValue(dbValue) {
            return dateFormatter.date(from: string)
        }
        return nil
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Date? {
        switch dbValue {
        case .integer(let int64):
            return Date(timeIntervalSince1970: Double(int64))
        case .real(let double):
            return Date(timeIntervalSince1970: double)
        case .text(let string):
            if let timestamp = Double.fromDatabaseValue(dbValue) {
                return Date(timeIntervalSince1970: timestamp)
            } else {
                return dateFormatter.date(from: string)
            }
        default:
            return nil
        }
    }
}

// MARK: Null
extension NSNull: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { return .null}
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Self? {
        return nil
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
        return nil
    }
}

// MARK: Data
extension Data: DatabaseValueConvertible, StatementColumnConvertible {
    public init(sqliteStatement: SQLiteStatement, index: Int32) throws {
        if let bytes = sqlite3_column_blob(sqliteStatement, Int32(index)) {
            let count = Int(sqlite3_column_bytes(sqliteStatement, Int32(index)))
            self.init(bytes: bytes, count: count) // copy bytes
        } else {
            self.init()
        }
    }
    
    public var databaseValue: DatabaseValue {
        return .blob(self)
    }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Data? {
        guard let data = dbValue as? Data else {
            return nil
        }
        return data
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Data? {
        switch dbValue {
        case .blob(let data):
            return data
        default:
            return nil
        }
    }
}

// MARK: URL
extension URL: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        return .text(self.absoluteString)
    }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> URL? {
        guard let string = String.fromDatabaseValue(dbValue) else {
            return nil
        }
        return URL(string: string)
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> URL? {
        guard let string = String.fromDatabaseValue(dbValue) else {
            return nil
        }
        return URL(string: string)
    }
}

// MARK: NSNumber
extension NSNumber: DatabaseValueConvertible {
    /// Cast value as Int64, UInt64 or Double. Return nil if casting failed.
    public var databaseValue: DatabaseValue {
        if let int64 = self as? Int64 {
            return int64.databaseValue
        } else if let uint64 = self as? UInt64 {
            return uint64.databaseValue
        } else if let double = self as? Double {
            return double.databaseValue
        } else {
            return .null
        }
    }
    
    /// Fetching a value as NSNumber is not supported
    public static func fromDatabaseValue(_ dbValue: Any) -> Self? {
        return nil
    }
    
    /// Fetching a value as NSNumber is not supported
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
        return nil
    }
}

extension NSString: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        return .text(self as String)
    }
    
    public static func fromDatabaseValue(_ dbValue: Any) -> Self? {
        return dbValue as? Self
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
        guard case .text(let stringValue) = dbValue else {
            return nil
        }
        return stringValue as? Self
    }
}

/// The DatabaseDate date formatter for stored dates.
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()
