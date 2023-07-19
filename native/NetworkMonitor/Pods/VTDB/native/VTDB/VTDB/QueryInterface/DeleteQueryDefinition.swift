//
//  DeleteQueryDefinition.swift
//  VTDB
//
//  Created by Dal Bahadur Thapa on 17/04/18.
//  Copyright © 2018 Zoho Corp. All rights reserved.
//

import Foundation

final class DeleteQueryDefinition: QueryDefinition {
    #if SQLEncrypted
    override func sql(_ db: Database) -> String {
        var encryptedColumns: Set<String> = []
        if case .table(let tableName, _) = source, let _ = db.encryption {
            encryptedColumns = try! db.encryptedColumns(in: tableName) ?? []
        }
        var query = "DELETE FROM " + source.expressionSQL(db, encryptedColumns: encryptedColumns)
        
        if !filter.isEmpty {
            query += " WHERE " + filter.map {
                $0.expressionSQL(db, encryptedColumns: encryptedColumns)
                }.joined(separator: " AND ")
        }
        
        // check if limit is enabled
        if limit != nil {
            if !orderBy.isEmpty {
                query += " ORDER BY " + orderBy.map {
                    $0.expressionSQL(db, encryptedColumns: encryptedColumns)
                }.joined(separator: ", ")
            }
            query += " LIMIT ?"
            if offset != nil {
                query += " OFFSET ?"
            }
        }
        return query
    }
    #else
    override func sql() -> String {
        var query = "DELETE FROM " + source.expressionSQL
        if !filter.isEmpty {
            query += " WHERE " + filter.map { $0.expressionSQL }.joined(separator: " AND")
            if limit != nil {
                if !orderBy.isEmpty {
                    query += " ORDER BY " + orderBy.map { $0.expressionSQL }.joined(separator: ", ")
                }
                query += " LIMIT ?"
                if offset != nil {
                    query += " OFFSET ?"
                }
            }
        }
        return query
    }
    #endif
    
    override func parameters() -> [DatabaseValueConvertible?] {
        var parameters: [DatabaseValueConvertible?] = []
        add(expressions: filter, to: &parameters)
        add(expressions: orderBy, to: &parameters)
        if let limit = limit {
            parameters.append(limit)
            if let offset = offset {
                parameters.append(offset)
            }
        }
        return parameters
    }
}
