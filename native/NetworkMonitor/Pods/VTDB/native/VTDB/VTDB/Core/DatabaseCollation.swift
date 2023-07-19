//
//  DatabaseCollation.swift
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

final class DatabaseCollation {
    let name: String
    let function: (String, String) -> ComparisonResult
    
    init(name: String, function: @escaping (String, String) -> ComparisonResult) {
        self.name = name
        self.function = function
    }
    
    func function(lhsBytes: UnsafeRawPointer?, lhsCount: Int32, rhsBytes: UnsafeRawPointer?, rhsCount: Int32) -> Int32 {
        guard
            let lhsBytes = lhsBytes,
            let rhsBytes = rhsBytes,
            let lhs = String(data: Data(bytes: lhsBytes, count: Int(lhsCount)), encoding: .utf8),
            let rhs = String(data: Data(bytes: rhsBytes, count: Int(rhsCount)), encoding: .utf8)
            else { return Int32(ComparisonResult.orderedAscending.rawValue) }
        
        return Int32(function(lhs, rhs).rawValue)
    }
}

extension DatabaseCollation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: DatabaseCollation, rhs: DatabaseCollation) -> Bool {
        return sqlite3_stricmp(lhs.name, rhs.name) == 0
    }
}

extension Database {
    
    func create(collation: DatabaseCollation) throws {
        let collationPointer = Unmanaged.passUnretained(collation).toOpaque()
        let code = sqlite3_create_collation_v2(
            sqliteConnection,
            collation.name,
            SQLITE_UTF8,
            collationPointer,
            { (collationPointer, lhsCount, lhsBytes, rhsCount, rhsBytes) in
                guard let collationPointer = collationPointer else { return -1 }
                let collation = Unmanaged<DatabaseCollation>.fromOpaque(collationPointer).takeUnretainedValue()
                return collation.function(lhsBytes: lhsBytes, lhsCount: lhsCount, rhsBytes: rhsBytes, rhsCount: rhsCount)
        }, nil)
        
        guard code == SQLITE_OK else {
            Unmanaged<DatabaseCollation>.fromOpaque(collationPointer).release()
            throw DatabaseError(database: self)
        }
    }

    public func create(collation name: String, function: @escaping (String, String) -> ComparisonResult) throws {
        let collation = DatabaseCollation(name: name, function: function)
        try create(collation: collation)
    }
    
    public func remove(collation name: String) {
        sqlite3_create_collation_v2(sqliteConnection, name, SQLITE_UTF8, nil, nil, nil)
    }
}
