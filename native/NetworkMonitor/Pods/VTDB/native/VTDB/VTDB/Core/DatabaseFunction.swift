//
//  DatabaseFunction.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 23/05/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation
#if SQLCipher
import SQLCipher
#else
import SQLite3
#endif

class DatabaseFunction {
    let name: String
    let deterministic: Bool
    let nArg: Int32
    let function: (Int32, UnsafeMutablePointer<OpaquePointer?>?) throws -> DatabaseValueConvertible?
    var eTextRep: Int32 {
        return deterministic ? SQLITE_UTF8 | SQLITE_DETERMINISTIC : SQLITE_UTF8
    }
    
    init(name: String, argumentCount: Int8? = nil, deterministic: Bool = false, function: @escaping ([DatabaseValue]) throws -> DatabaseValueConvertible?) {
        self.name = name
        if let argumentCount = argumentCount {
            nArg = argumentCount < 0 ? -1 : Int32(argumentCount)
        } else {
            nArg = -1
        }
        self.deterministic = deterministic
        self.function = { (argc, argv) in
            let arguments = (0..<Int(argc)).map { index in
                DatabaseValue(sqliteValue: argv.unsafelyUnwrapped[index]!)
            }
            return try function(arguments)
        }
    }
    
    func install(in db: Database) throws {
        // Retain the function definition
        let definition = FunctionDefinition(compute: function)
        let definitionP = Unmanaged.passRetained(definition).toOpaque()
        
        let code = sqlite3_create_function_v2(db.sqliteConnection, name, nArg, eTextRep, definitionP, { (sqliteContext, argc, argv) in
            let definition = Unmanaged<FunctionDefinition>.fromOpaque(sqlite3_user_data(sqliteContext)).takeUnretainedValue()
            do {
                try DatabaseFunction.report(
                    result: definition.compute(argc, argv),
                    in: sqliteContext)
            } catch {
                DatabaseFunction.report(error: error, in: sqliteContext)
            }
        }, nil, nil, { definitionP in
            // Release the function definition
            Unmanaged<AnyObject>.fromOpaque(definitionP!).release()
        })
        
        guard code == SQLITE_OK else {
            throw DatabaseError(code: code, message: db.lastErrorMessage)
        }
    }
    
    private class FunctionDefinition {
        let compute: (Int32, UnsafeMutablePointer<OpaquePointer?>?) throws -> DatabaseValueConvertible?
        init(compute: @escaping (Int32, UnsafeMutablePointer<OpaquePointer?>?) throws -> DatabaseValueConvertible?) {
            self.compute = compute
        }
    }
    
    private static func report(result: DatabaseValueConvertible?, in sqliteContext: OpaquePointer?) {
        switch result?.databaseValue ?? .null {
        case .null:
            sqlite3_result_null(sqliteContext)
        case .integer(let int64):
            sqlite3_result_int64(sqliteContext, int64)
        case .real(let double):
            sqlite3_result_double(sqliteContext, double)
        case .text(let string):
            sqlite3_result_text(sqliteContext, string, -1, SQLITE_TRANSIENT)
        case .blob(let data):
            data.withUnsafeBytes { bytes in
                sqlite3_result_blob(sqliteContext, bytes, Int32(data.count), SQLITE_TRANSIENT)
            }
        }
    }
    
    private static func report(error: Error, in sqliteContext: OpaquePointer?) {
        if let error = error as? DatabaseError {
            if let message = error.message {
                sqlite3_result_error(sqliteContext, message, -1)
            }
            sqlite3_result_error_code(sqliteContext, error.extendedErrorCode)
        } else {
            sqlite3_result_error(sqliteContext, "\(error)", -1)
        }
    }
}

extension DatabaseFunction: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(nArg)
    }
    
    public static func ==(_ lhs: DatabaseFunction, _ rhs: DatabaseFunction) -> Bool {
        return lhs.name == rhs.name && lhs.nArg == rhs.nArg
    }
}

extension Database {
    
    public func addFunction(named name: String, argumentCount: Int8? = nil, deterministic: Bool = false, function: @escaping ([DatabaseValue]) throws -> DatabaseValueConvertible?) throws {
        let dbFunction = DatabaseFunction(name: name, argumentCount: argumentCount, deterministic: deterministic, function: function)
        try dbFunction.install(in: self)
    }
    
    func add(function: DatabaseFunction) throws {
        try function.install(in: self)
    }
    
    public func removeFunction(named name: String, argumentCount: Int8? = nil) {
        let nArg: Int32
        if let argumentCount = argumentCount {
            nArg = argumentCount < 0 ? -1 : Int32(argumentCount)
        } else {
            nArg = -1
        }
        sqlite3_create_function_v2(sqliteConnection, name, nArg, SQLITE_UTF8, nil, nil, nil, nil, nil)
    }
}
